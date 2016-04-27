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
labelOfSource() { basename "$1" | \sed -e 's|\.[a-z]*$||' -e 's|\.skip$||'; }
declare -r genFileExts=(c diff actual stderr a)
declare -r suiteLog="$(labelOfSource "$0")".log
declare -r srcExt=eq

# CLI arguments & APIs
declare -r thisScript="$(basename "$0")"
declare -r eqToObj="$(dirname "$0")/eq-to-obj.sh"
declare -r allopts=kvhdcsp
opt_runSkip=0 # s
opt_verbose=0 # v
opt_keep=0    # k
opt_debug=0   # d
opt_plain=0   # p
Usage() {     # h
  echo -e "
  Usage: $thisScript -[$allopts] [LANG_SOURCE_FILES]

  Where LANG_SOURCE_FILES is one or more EqualsEquals file, in the form:
  - test-[testlabel].$srcExt where 'testlabel' is some meaningful name of an
    expected sucessful test program
  - fail-[testlabel].$srcExt where 'testlabel' is some meaningful name of an
    expected invalid test program

  Options:
    -k    Keeps intermediate files after testing; default: $opt_keep
           - TEST_SOURCE.c\tTEST_SOURCE's compiled target output.
           - TEST_SOURCE.diff\tshowing difference in case of failures
           - TEST_SOURCE.actual\tstderr & stdout of TEST_SOURCE's behavior
           - TEST_SOURCE.stderr\tTEST_SOURCE's compile-time errors.
           - TEST_SOURCE.a\tTEST_SOURCE's compiled target.

    -v    Verbose print of failures' actual vs. expected; default: $opt_verbose
          Note: -p flag takes precedence over this flag

    -d    Debug this script's behavior, with bash commands/args printed.

    -c    Cleanup generated files and exit; default: false

    -s    Run [s]kipped tests despite being marked 'skip'; default: $opt_runSkip

    -p    [P]laintext output for script consumption; default: $opt_plain
          Note: overrides -v flag

    -h    Print this help message
    \r" >&2
    exit 1
}

if [ "$(uname -s)" = Darwin ];then
  rlnk_f() { echo -n $@; }
else
  rlnk_f() { readlink -f $@; }
fi

cleanGeneratedFiles() {
  echo 'Cleaning up old generated e2e-test files...'
  for genExt in "${genFileExts[@]}";do
    for gen in tests/{test,fail}-*".$genExt";do
      rmIfExists "$gen"
    done
    rmIfExists "$suiteLog"
  done
}

col() {
  local c=$1  esc=0 ;shift

  if [ "$opt_plain" -eq 1 ] || [ "$(uname -s)" = Darwin ];then
    echo -ne "$@"
    return
  fi

  case "$c" in
    red) esc='\e[1;31m';;
    grn) esc='\e[1;32m';;
    blu) esc='\e[1;34m';;
    ylw) esc='\e[1;33m';;
  esac
  echo -ne $esc"$@"'\033[0m'
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
      cleanGeneratedFiles

      exit 0
      ;;
    s) opt_runSkip=1;;
    p) opt_plain=1;;
    h) Usage ;;
  esac
done
if [ "$opt_plain" -eq 1 ];then opt_verbose=0;fi
shift $(( OPTIND - 1 ))


# Path to the our compiler.
#   Try "_build/eqeq.native" if ocamlbuild was unable to create a symbolic link.
declare -r eqCompiler="$(rlnk_f "./eqeq.native")"
[ -x "$eqCompiler" ] || {
  printf 'CRITICAL: no EqEq compiler found at "%s"!\n' "$eqCompiler"
  exit 1
}
rmIfExists "$suiteLog" >/dev/null

# Determine which test files we're running
if [ "$1" = help ];then
  Usage
elif [ $# -ge 1 ]; then
  testFiles=($*)
else
  testFiles=($(
    find tests/ \
      -type f \
      -name "fail-*.$srcExt"\
      -o \
      -name "test-*.$srcExt"
  ))
fi

log() {
  local maybeStderr=2
  if [ "$opt_plain" -eq 1 ];then maybeStderr=/dev/null; fi
  cat /dev/stdin | tee -a "$suiteLog" >&"$maybeStderr"
}

diffFiles()  { \diff --ignore-space-change "$1" "$2"; }
printUnitResult() { printf '\tResult:\t%s\n' "$1" | log; } # usage: [PASS|FAIL]
unitTagFromExit() { if [ $1 -eq 0 ];then col grn PASS; else col red FAIL;fi }
# Get path to sibling we'll be generating with suffix $1 as sibling to $2
pathToGenSib() {
  local suffix="$1"; [ -n "$suffix" ]
  local sibling="$(rlnk_f "$2")"; [ -f "$sibling" ]
  local dir="$(dirname "$sibling")"

  local newFile="$dir"/"$(labelOfSource "$sibling").${suffix}"

  printf '%s' "$newFile"
}
ensureFirstSibling() {
  local path; path="$(pathToGenSib $@)"
  [ -f "$path" ] && return 1
  echo "$path"
}

# usage: pass compiler's exit codes; $1=expected $2=actual
isCompilerExitExpected() {
  local expt="$1"; local actu="$2"
  { [ "$expt" -eq 0 ] && [ "$actu" -eq 0 ]; } ||
    { [ "$expt" -ne 0 ] && [ "$actu" -gt 0 ]; }
}

# usage: testprog EXPECTEXIT testNum
#  Where EXPECTEXIT is 0 if expecting passing `testprog`, 1 otherwise
CheckTest() {
  local eqTestSrc="$(rlnk_f "$1")"
  local testDir="$(dirname "$eqTestSrc")"
  local expectExit=$2; { [ "$expectExit" -eq 0 ] || [ "$expectExit" -eq 1 ]; }
  local testNum=$3

  # Print what we're up to
  local labelBlu="$(col blu "$(labelOfSource "$eqTestSrc")")"
  local expectSummary="$(
    if [ "$expectExit" -eq 0 ];then
      echo "target's behavior"
    else
      echo 'compilation fails'
    fi
  )"
  printf '[%2d] "%s"\tasserting %s\t' \
    $testNum "$labelBlu" "$expectSummary" | log

  # Derivative files we expect present
  local expected="$(pathToGenSib "$(
    if [ "$expectExit" -eq 0 ];then printf out; else printf err;fi
  )" "$eqTestSrc")";
  if ! [ -f "$expected" ];then
    printUnitResult $(unitTagFromExit 1)
    printf \
      'BUG: cannot test without expecation file:\n\t%s\n' \
      "$expected" | log
    return 1
  fi

  # files we'll generate
  local eqTarget="$(ensureFirstSibling c "$eqTestSrc")"
  local eqTargetObj="$(ensureFirstSibling a "$eqTestSrc")"
  local compilerErrs="$(ensureFirstSibling stderr "$eqTestSrc")"
  local actual="$(ensureFirstSibling actual "$eqTestSrc")"
  local diffR="$(ensureFirstSibling diff "$eqTestSrc")"

  # Actually run test program
  "$eqCompiler" < "$eqTestSrc" > "$eqTarget" 2> "$compilerErrs" && actualExit=$? || actualExit=$?

  if isCompilerExitExpected "$expectExit" "$actualExit"; then
    # EqEq compiler treated sample source as expected

    local left="$expected" right="$actual"
    if [ "$expectExit" -eq 0 ];then
      local buildLog; buildLog="$("$eqToObj" "$eqTarget" -o "$eqTargetObj" 2>&1)"
      local buildStatus=$?; echo -n "$buildLog" | log
      if [ $buildStatus -ne 0 ];then
        printf \
          "\n\tCRITICAL:\tEqEq's source test unexpectedly fails to compile!\n" |
          log
        return 1
      fi

      # Run our compield test target (itself compiled with eqCompiler)
      "$eqTargetObj" > "$actual" 2>&1
    else
      right="$compilerErrs"
    fi

    diffFiles "$left" "$right" > "$diffR"
    printUnitResult "$(unitTagFromExit $?)"
    if [ "$opt_verbose" -eq 1 ];then
      cat "$diffR" | log
    fi

    [ "$(wc -l < "$diffR")" -eq 0 ]; return $?
  else
    # EqEq compiler did opposite of what we expected with sample source

    printUnitResult $(unitTagFromExit 1)
    if [ "$expectExit" -eq 0 ];then
      printf '\tEqEq source unexpectedly failed to compile\n' | log
    else
      printf '\tBad EqEq source compiled, but failure expected\n' | log
    fi
    return 1
  fi
  return 0
}

isTestPresent() {
  local label d;
  d="$(dirname "$(rlnk_f "$1")")";
  label="$(labelOfSource "$1")"
  [ -f "$1" ] && { [ -f "$d"/"${label}.out" ] || [ -f "$d"/"${label}.err" ]; }
}

# Running with *previously* generated files just makes my brain explode...
cleanGeneratedFiles | log
touch "$suiteLog"

# Print test suite outline
if [ "$opt_plain" -eq 0 ];then
  printf '\nRunning %s:\n%s\n' \
    "$(col blu "$(printf '%d tests' ${#testFiles[@]})")" \
    "$(pr -tw90 -3 <(
      for file in ${testFiles[@]}; do
        printf '  "%s"\n' "$(
          labelOfSource "$file" |
            sed -e 's|^test-||' -e 's|^fail-||' -e 's|-| |g'
        )"
      done
    ))"
fi

# Returns "N%" where N is $2's percentage of $1
percWhole() { printf '%d%%' $(printf '100 - (%d/(%d - %d))\n' $1 $1 $2 | bc); }

# Test suite's stats:
testNum=0; numFail=0; numSkip=0; numPass=0;
logPlain() {
  if [ "$opt_plain" -eq 0 ];then return 0; fi

  local label="$1" status="$2"
  printf '%s\t%s\n' "$status" "$label"
}
skip() {
  local testNum="$1"; shift 1;
  printf '[%2d] %s\t%s\tResult: %s\n' \
    $testNum "$(col blu WARNING)" "$*" "$(col ylw SKIP)" | log
  numSkip=$(( numSkip + 1 ))
}
isMarkedSkip() { echo "$1" | \grep -E ".*-.*\.skip\.$srcExt" >/dev/null; }

sincePreviousTestLine=1
for testFile in "${testFiles[@]}"; do
  failed=0; testNum=$(( testNum + 1 ))
  label="$(labelOfSource "$testFile")"

  if isMarkedSkip "$testFile" && [ "$opt_runSkip" -eq 0 ];then
    skip $testNum "'$label' not implemented"
    logPlain "$label" SKIP
    continue;
  fi

  case "$(basename "$testFile")" in
    test-*.$srcExt) expectExit=0;;
    fail-*.$srcExt) expectExit=1;;
    *)
      skip $testNum "not a fail or test file '$testFile'"
      logPlain "$label" SKIP
      continue;
      ;;
  esac

  if ! isTestPresent "$testFile";then
    printf '[%2d] %s\tBad test: no .out/.err for "%s"\tResult: %s\n' \
      $testNum "$(col red ERROR)" "$testFile" "$(col red FAIL)"
    numFail=$(( numFail + 1 ))
    continue;
  fi

  # Run test
  if CheckTest "$testFile" "$expectExit" "$testNum";then
    logPlain "$label" PASS
    numPass=$(( numPass + 1 ))
  else
    logPlain "$label" FAIL
    numFail=$(( numFail + 1 ))
  fi

  # Cleanup after each test
  if [ "$opt_keep" -eq 0 ];then
    for genExt in "${genFileExts[@]}";do
      gen="$(dirname "$testFile")"/"${label}.${genExt}"
      rmIfExists "$gen" >/dev/null
    done
  fi

  # Verbose-printing of logs
  if [ "$failed" -eq 1 ] && [ "$opt_verbose" -eq 1 ];then
    sed -n "$(( sincePreviousTestLine + 1 )),$"p "$suiteLog"
  fi

  sincePreviousTestLine="$(wc -l < "$suiteLog")"
done

# Print test suite summary
if [ "$opt_plain" -eq 0 ];then
  printf '\n%s of %d tests:\t%s%s%s\n' \
    "$(col blu Summary)" \
    "${#testFiles[@]}" \
    "$(if [ "$numFail" -gt 0 ];then col red "$numFail FAILED\t";fi)" \
    "$(if [ "$numSkip" -gt 0 ];then col ylw "$numSkip SKIPPED\t";fi)" \
    "$(col grn "$numPass PASSED") [$(percWhole ${#testFiles[@]} $numPass)]"
else
  echo "TOTAL FAILED $numFail"
  echo "TOTAL SKIPPED $numSkip"
  echo "TOTAL PASSED $numPass"
fi

[ "$numFail" -eq 0 ]
