#!/bin/zsh -f
# The res64 values are from genefer's src/main.cpp, lines 404, 405 and 413.
cd ${0:A:h}
fail=0
t() {
  local exe=$1 want=$2 out=out.txt rc; shift 2
  rm -rf build/check && mkdir -p build/check && cd build/check
  ../../bin/$exe "$@" >out.txt 2>&1; rc=$?
  [[ $1 == -boinc ]] && out=results.txt
  if (( rc == 0 )) && grep -q "res64 = $want" $out 2>/dev/null &&
     [[ $1 != -boinc || $(cat boinc_finish_called 2>/dev/null) == 0 ]]; then
    echo "ok   $exe $*"
  else
    echo "FAIL $exe $* (exit $rc)"; fail=1
  fi
  cd ../..
}
t genefer_mac_arm 4E43A5B93273C649 -q -n 12 -b 1000000000 -t 1
t genefer_mac_arm 4E43A5B93273C649 -boinc -q -n 12 -b 1000000000 -t 1
t geneferg_mac_arm E5F3EA34F6C68EBD -q -n 12 -b 2000000000
t geneferg_mac_arm AD5434699AA36C6F -q -n 13 -b 1000000000
exit $fail
