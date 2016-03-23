#!/usr/bin/env bash
#
# Regression testing script for EqualsEquals
# Steps through a list of files
#  Compiles, runs, and check the output of each expected-to-work test
#  Compile and check the error of each expected-to-fail test
set -e
ulimit -t 30  # Set time limit for all operations

#... high-level maintenance
rmIfExists() { if [ -f "$1" ];then rm -v "$1";fi; }
declare -r genFileExts=(c diff actual stderr a)

# CLI arguments & APIs
declare -r thisScript="$(basename "$0")"
declare -r allopts=kvhdc
opt_verbose=0 # v
opt_keep=0    # k
opt_debug=0   # d
Usage() {     # h
    echo -e "
  Usage: $thisScript -[$allopts] [LANG_SOURCE_FILES]

  Where LANG_SOURCE_FILES is one or more EqualsEquals file, in the form:
  - test-[testlabel].eq where 'testlabel' is some meaningful name of an
    expected sucessful test program
  - fail-[testlabel].eq where 'testlabel' is some meaningful name of an
    expected invalid test program

  Options:
    -k    Keeps intermediate files after testing; default: $opt_keep
           - TEST_SOURCE.c\tTEST_SOURCE's compiled target output.
           - TEST_SOURCE.diff\tshowing difference in case of failures
           - TEST_SOURCE.actual\tstderr & stdout of TEST_SOURCE's behavior
           - TEST_SOURCE.stderr\tTEST_SOURCE's compile-time errors.
           - TEST_SOURCE.a\tTEST_SOURCE's compiled target.

    -v    Verbose print of failures' actual vs. expected; default: $opt_verbose

    -d    Debug this script's behavior, with bash commands/args printed.

    -c    Cleanup generated files and exit; default: false

    -h    Print this help message
    \r" >&2
    exit 1
}

# Parse command line arguments ASAP
while getopts "$allopts" c; do
    case $c in
        k) opt_keep=1 ;;
        v) opt_verbose=1 ;;
        d)
          set -x
          opt_debug=1
          ;;
        c)
          echo 'Cleaning up test files...'
          for genExt in "${genFileExts[@]}";do
            for gen in tests/{test,fail}-*".$genExt";do
              rmIfExists "$gen"
            done
            rmIfExists "$globallog"
          done

          exit 0
          ;;
        h) Usage ;;
    esac
done
shift $(( OPTIND - 1))

# Path to the our compiler.
#   Try "_build/eqeq.native" if ocamlbuild was unable to create a symbolic link.
declare -r eqCompiler="./eqeq.native"
[ -x "$eqCompiler" ] || {
  printf 'CRITICAL: no EqEq compiler found at "%s"!\n' "$eqCompiler"
  exit 1
}
declare -r globallog=testall.log;
rmIfExists "$globallog" >/dev/null

# Determine which test files we're running
if [ $# -ge 1 ]; then
    testFiles=$@
else
    testFiles=(tests/test-*.eq tests/fail-*.eq)
fi

labelOfSource() { basename "$1" | \sed -e 's|\..*||g'; }
diffFiles()  { \diff --ignore-space-change "$1" "$2"; }
isMatch() { diffFiles "$1" "$2" >/dev/null 2>&1; }

# usage: [PASS|FAIL]
printUnitResult() { printf '\tResult:\t%s\n' "$1" >&2 | tee -a "$globallog"; }
unitTagFromExit() { if [ $1 -eq 0 ];then echo PASS; else echo FAIL;fi }
checkExists() { [ -f "$1" ]; }

# usage: testprog [EXPECTEXIT]
#  Where EXPECTEXIT is 0 if expecting passing `testprog`, 1 otherwise
CheckTest() {
  local eqTestSrc="$(readlink -f "$1")"; local testDir="$(dirname "$1")"
  local expectExit=$2; { [ "$expectExit" -eq 0 ] ||  [ "$expectExit" -eq 1 ]; }

  local testLabel="$(labelOfSource "$eqTestSrc")"
  ! checkExists "$expected"

  # Derivative files we expect present
  local eqTest="${testLabel}.eq"
  local expected="${testLabel}.$(
    if [ "$expectExit" -eq 0 ];then printf out; else printf err;fi
  )"; checkExists "$expected"

  # files we'll generate
  local eqTarget="$testDir"/"${testLabel}.c"
  local eqTargetObj="$testDir"/"${testLabel}.a"
  local compilerErrs="$testDir"/"${testLabel}.stderr"
  local actual="$testDir"/"${testLabel}.actual"
  local diffR="$testDir"/"${testLabel}.diff"

  # Print what we're up to
  local expectSummary="$(
    if [ "$expectExit" -eq 0 ];then
      echo 'resulting program behavior'
    else
      echo 'compilation failure'
    fi
  )"
  printf '#### Testing "%s" for its %s\n' "$testLabel" "$expectSummary" |
      tee -a "$globallog"

  # Finally run our test
  { "$eqCompiler" < "$eqTestSrc" > "$eqTarget" 2 > "$compilerErrs" || true; } |
      tee -a "$globallog"
  actualExit=$?

  if [ "$actualExit" -eq "$expectExit" ]; then
    # EqEq compiler treated sample source as expected

    local left="$expected" right="$actual"
    if [ "$expectExit" -eq 0 ];then
      if ! cc "$eqTarget" -o "$eqTargetObj" 2>&1;then
        printf \
          "\tCRITICAL:\tEqEq's source test unexpectedly fails to compile!\n" \
          >> "$globallog"
          return 1
      fi

      # Run our compield test target (itself compiled with eqCompiler)
      "$eqTargetObj" > "$actual" 2>&1
    else
      right="$compilerErrs"
    fi

    printUnitResult "$(
      isMatch "$left" "$right"; unitTagFromExit $?
    )"
    diffFiles "$left" "$right" > "$diffR"
    if [ "$opt_verbose" -eq 1 ];then
      cat "$diffR" >&2
    fi

    isMatch "$left" "$right"; return $?
  else
      # EqEq compiler did opposite of what we expected with sample source

      if [ "$expectExit" -eq 0 ];then
        printf '\tEqEq source unexpectedly failed to compile\n' >> "$globallog"
      else
        printf \
          '\tBad EqEq source compiled, but failure expected\n' >> "$globallog"
      fi
    printUnitResult $(unitTagFromExit 1)
    return 1
  fi
  return 0
}

touch "$globallog"
sincePreviousTestLine=1
for testFile in $testFiles; do
    case $testFile in
        *test-*)
            expectExit=0
            ;;
        *fail-*)
            expectExit=1
            ;;
        *)
            printf 'Skipping UNKNOWN test file:\t"%s"\n' "$testFile"
            anyFailures=1
            continue;
            ;;
    esac

    # Run test
    if ! CheckTest "$testFile" "$expectExit" 2>&1;then
      anyFailures=1
    fi

    if [ "$opt_keep" -eq 0 ];then
      for genExt in "${genFileExts[@]}";do
        rmIfExists \
          "$(dirname "$testFile")"/"$(labelOfSource "$testFile").${genExt}"
      done
    fi

    # Verbose-printing of logs
    if [ "$opt_verbose" -eq 1 ];then
      sed -n "${sincePreviousTestLine},$"p "$globallog"
    fi

    sincePreviousTestLine="$(wc -l < "$globallog")"
done

exit $anyFailures
