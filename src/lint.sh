#!/usr/bin/env bash
set -e

declare -r diffExec="$(
  if type colordiff >/dev/null 2>&1;then
    echo colordiff
  else
    echo diff
  fi
)"

declare -r expectedOcamlDep="$(
  {
    make clean &&
      make scanner &&
      make parser
  } >/dev/null && ocamldep *.ml{,i}
)"
declare -r expectedLineCount="$(echo "$expectedOcamlDep" | wc -l)"

"$diffExec" --unified \
  <(tail --lines "$expectedLineCount" ./Makefile) \
  <(echo "$expectedOcamlDep") || {
  printf '\n\e[1;31mERROR\033[0m: generated `ocamldep` in Makefile is out of date\n\n' >&2
  exit 1
}
