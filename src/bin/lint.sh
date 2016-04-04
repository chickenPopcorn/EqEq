#!/usr/bin/env bash
set -e

clean() { make clean >/dev/null; }
lintFound=0
recordLint() {
  printf '\n\e[1;31mLINT FOUND\033[0m:\t%s\n' "$@" >&2
  lintFound=1
}

clean # before running new lint check...
make eqeq | grep shift.reduce >/dev/null && recordLint \
  'Scanner & Parser has "shift/reduce" and/or "reduce/reduce" conflicts'

clean # before running new lint check...
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
  <(tail -n "$expectedLineCount" ./Makefile) \
  <(echo "$expectedOcamlDep") ||
  recordLint 'generated `ocamldep` in Makefile is out of date'

clean # before running new lint check...
getPassingTests() { make TEST_OPTS="$@" test 2>&1 | \grep '^PASS' | cut -f 2 | \sort; }
declare -r currentPassing="$(getPassingTests -p)"
declare -r skippedPassing="$(getPassingTests -ps)"
[ "$currentPassing" != "$skippedPassing" ] &&
  recordLint "Some PASSING tests are unnecessarily skipped: $(
    printf '\n%s' "$(
      grep -vf \
        <(printf '%s\n' "$currentPassing") \
        <(printf '%s\n' "$skippedPassing")
    )"
  )"

clean # before running new lint check...
isPatternMatchOld() { grep 'Warning.*this.pattern.matching.is.not.exhaustive'; }
makeDebugTokens() { clean && make debugtokens; }
if ! makeDebugTokens >/dev/null 2>&1 ||
  makeDebugTokens 2>&1 | isPatternMatchOld;then
  recordLint \
    'Scanner&Parser changes not shared w/debugtokens! See: `make debugtokens`'
fi

printf '\n' >&2 # visual bumper
exit $lintFound
