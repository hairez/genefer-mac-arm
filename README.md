# genefer for Apple silicon Macs

[genefer](https://github.com/galloty/genefer22) 26.04.0 for PrimeGrid on Apple silicon Macs with macOS 11 or later. `genefer_mac_arm` runs on the CPU and `geneferg_mac_arm` on the GPU (OpenCL). Both are unmodified genefer at commit [0172532](https://github.com/galloty/genefer22/commit/0172532c55f710865f7488b40e883a672415f1f7), built with Apple clang 16.0.0 and linked statically with GMP 6.3.0 and the BOINC 7.24.3 API, so they need only macOS system libraries. They are not notarized. Downloads and checksums are on the [releases page](https://github.com/hairez/genefer-mac-arm/releases).

Tested only on an M4 Max with macOS 15.7.9. Quick tests (`-q`) of both programs give the residues in genefer's src/main.cpp, and a full GFN-18 test of 100000002^262144+1 on the CPU (2 h 11 min on 4 threads) passed its proof and certificate checks. The same GPU code, built for macOS 15, had 1950 GFN-17 Mega tasks validated on that Mac and none invalid. With `app_info_cpu.xml` under BOINC 7.24.4, the CPU build has had a GFN-18 task validated on PrimeGrid. The GPU build has not run PrimeGrid tasks yet.

## Running on PrimeGrid

1. In BOINC Manager, set PrimeGrid to No New Tasks, let its tasks finish and report them (Update) until none are left, then quit BOINC. BOINC deletes tasks still on the Mac when app_info.xml is added or removed.
2. Unzip the download and run `xattr -d com.apple.quarantine genefer_mac_arm geneferg_mac_arm` in that folder, or macOS will refuse to run them.
3. Edit `app_info_cpu.xml` or `app_info_gpu.xml` as described below, rename it to `app_info.xml` and copy it with its program to the PrimeGrid project folder, normally `/Library/Application Support/BOINC Data/projects/www.primegrid.com/`.
4. Start BOINC, allow new tasks, and enable the matching subproject for CPU or GPU in the PrimeGrid preferences.

`app_info_cpu.xml` runs GFN-18 on 4 threads; change `avg_ncpus` and `-t` to suit. `app_info_gpu.xml` runs GFN-17 Mega, and its `<type>` must be your GPU's name as BOINC's event log prints it at startup (`OpenCL: Apple M4 Max 0: ...`). The GPU tasks ran under BOINC 7.24.4; with BOINC 8.2.15 PrimeGrid sent the same Mac no GPU tasks. With app_info.xml in place, BOINC runs only the apps it lists.

To go back, repeat step 1, delete `app_info.xml`, start BOINC and reset the PrimeGrid project.

Please post results in the [PrimeGrid forum thread](https://www.primegrid.com/forum_thread.php?id=14394).

## Building

`./build.sh && ./check.sh`, with the Xcode command line tools. build.sh downloads genefer, GMP and BOINC and builds both programs into bin/; check.sh runs a few short tests.

## License

The scripts are MIT, like genefer. GMP is LGPL v3 or GPL v2 and BOINC is LGPL v3, each or later. The release includes the sources of all three.
