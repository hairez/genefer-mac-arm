#!/bin/zsh -f
# Builds bin/genefer_mac_arm (CPU) and bin/geneferg_mac_arm (GPU).
set -euo pipefail
cd ${0:A:h}

genefer=0172532c55f710865f7488b40e883a672415f1f7
boinc_tag=client_release/7.24/7.24.3
boinc=b76eff441d072132eff1f7dba3abd9f4a5648303
gmp_sha256=a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898

export MACOSX_DEPLOYMENT_TARGET=11.0
arch=(-arch arm64 -mmacosx-version-min=11.0)
mkdir -p build bin
rm -f bin/genefer_mac_arm bin/geneferg_mac_arm
cd build

# The sources archive in the release has no .git, so only clones are checked.
pinned() {
  [[ -d $1/.git ]] || return 0
  [[ $(git -C $1 rev-parse HEAD) == $2 && -z $(git -C $1 status --porcelain --untracked-files=no) ]] ||
    { echo "build/$1 is not a clean checkout of $2" >&2; exit 1 }
}
[[ -d genefer22 ]] || { git clone -q https://github.com/galloty/genefer22 && git -C genefer22 checkout -q $genefer }
[[ -d boinc ]] || git -c advice.detachedHead=false clone -q --depth 1 --branch $boinc_tag https://github.com/BOINC/boinc
pinned genefer22 $genefer
pinned boinc $boinc
[[ -f gmp-6.3.0.tar.xz ]] || curl -fsSLO https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz
[[ $(shasum -a 256 gmp-6.3.0.tar.xz | cut -d' ' -f1) == $gmp_sha256 ]] ||
  { rm -f gmp-6.3.0.tar.xz; echo "gmp-6.3.0.tar.xz had the wrong sha256 and was deleted, run again" >&2; exit 1 }

if [[ ! -f gmp/lib/libgmp.a ]]; then
  rm -rf gmp-6.3.0 gmp-build && tar -xf gmp-6.3.0.tar.xz && mkdir gmp-build
  (cd gmp-build && ../gmp-6.3.0/configure --prefix=$PWD/../gmp --disable-shared --enable-static CC="clang $arch" &&
    make -j4 && make install) >gmp.log 2>&1 || { echo "GMP build failed, see build/gmp.log" >&2; exit 1 }
fi

b=$PWD/boinc
inc=(-I$b/clientgui/mac -I$b -I$b/lib -I$b/lib/mac -I$b/api)
rm -rf obj && mkdir obj
for s in app_ipc base64 cc_config cert_sig coproc diagnostics filesys hostinfo keyword md5 md5_file mem_usage \
         mfile miofile msg_log network notice opencl_boinc parse prefs procinfo proc_control project_init \
         proxy_info sched_msgs shmem str_util url util procinfo_mac mac/mac_backtrace mac/mac_spawn mac/mac_branding; do
  clang++ -std=c++17 -O2 $arch $inc -c $b/lib/$s.cpp -o obj/${s:t}.o
done
for s in QBacktrace QCrashReport QMachOImage QMachOImageList QSymbols QTaskMemory; do
  clang -O2 $arch $inc -c $b/lib/mac/$s.c -o obj/$s.o
done
ar rcs libboinc.a obj/*.o
clang++ -std=c++17 -O2 $arch $inc -c $b/api/boinc_api.cpp -o obj/boinc_api.o
clang++ -std=c++17 -O2 $arch $inc -c $b/api/boinc_opencl.cpp -o obj/boinc_opencl.o
ar rcs libboinc_api.a obj/boinc_api.o
ar rcs libboinc_opencl.a obj/boinc_opencl.o

src=genefer22/src
cpu=(-std=c++17 -O3 $arch -DBOINC -I$b -I$b/api -I$b/lib -Igmp/include -Igenefer22/Khronos)
fp=(-ffinite-math-only -ffp-contract=fast -fno-trapping-math -fno-signed-zeros)
clang++ $cpu -c $src/main.cpp -o obj/main.o
clang++ $cpu $fp -c $src/transform_neon.cpp -o obj/transform_neon.o
# Same objects as genefer's makefile_linux_arm. The SVE code never runs on a Mac.
clang++ $cpu -march=armv8-a+sve -c $src/sve_size.cpp -o obj/sve_size.o
for v in 128 256 512; do
  clang++ $cpu $fp -march=armv8-a+sve -msve-vector-bits=$v -c $src/transform_sve$v.cpp -o obj/transform_sve$v.o
done
clang++ -O3 $arch obj/{main,transform_neon,sve_size,transform_sve128,transform_sve256,transform_sve512}.o \
  libboinc_api.a libboinc.a gmp/lib/libgmp.a -framework IOKit -framework CoreFoundation -framework Carbon \
  -o ../bin/genefer_mac_arm

gpu=(-std=c++17 -O3 $arch -DGPU -DBOINC -Igmp/include -Igenefer22/Khronos -I$b -I$b/api -I$b/lib)
clang++ $gpu -c $src/main.cpp -o obj/maing.o
clang++ $gpu -c $src/transform_ocl.cpp -o obj/transform_ocl.o
clang++ -O3 $arch obj/maing.o obj/transform_ocl.o libboinc_api.a libboinc_opencl.a libboinc.a gmp/lib/libgmp.a \
  -framework OpenCL -framework IOKit -framework CoreFoundation -framework Carbon -o ../bin/geneferg_mac_arm

cd .. && shasum -a 256 bin/*
