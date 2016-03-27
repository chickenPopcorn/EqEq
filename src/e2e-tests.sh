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
labelOfSource() { basename "$1" | \sed -e 's|\..*||g'; }
declare -r genFileExts=(c diff actual stderr a)
declare -r suiteLog="$(labelOfSource "$0")".log
declare -r srcExt=eq

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

    -d    Debug this script's behavior, with bash commands/args printed.

    -c    Cleanup generated files and exit; default: false

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
  if [ "$(uname -s)" = Darwin ];then
    echo -ne "$@"
    return
  fi

  local c=$1  esc=0 ;shift
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
    h) Usage ;;
  esac
done
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
if [ $# -ge 1 ]; then
  testFiles=$*
else
  testFiles=($(
    find tests/ \
      -type f \
      -name "fail-*.$srcExt"\
      -o \
      -name "test-*.$srcExt"
  ))
fi

diffFiles()  { \diff --ignore-space-change "$1" "$2"; }
printUnitResult() { printf '\tResult:\t%s\n' "$1"; } # usage: [PASS|FAIL]
unitTagFromExit() { if [ $1 -eq 0 ];then col grn PASS; else col red FAIL;fi }
# Get path to sibling we'll be generating with suffix $1 as sibling to $2
pathToGenSib() {
  local suffix="$1"; [ -n "$suffix" ]
  local sibling="$(rlnk_f "$2")"; [ -d "$sibling" ]
  local dir="$(dirname "$sibling")"

  local newFile="$dir"/"$(labelOfSource "$sibling").${suffix}"

  printf '%s' "$newFile"
}
ensureFirstSibling() {
  local path; path="$(pathToGenSib $@)"
  [ -f "$path" ] && return 1
  echo "$path"
}

# usage: testprog EXPECTEXIT testNum
#  Where EXPECTEXIT is 0 if expecting passing `testprog`, 1 otherwise
CheckTest() {
  local eqTestSrc="$(rlnk_f "$1")"
  local testDir="$(dirname "$eqTestSrc")"
  local expectExit=$2; { [ "$expectExit" -eq 0 ] || [ "$expectExit" -eq 1 ]; }
  local testNum=$3

  # Print what we're up to
  local expectSummary="$(
    if [ "$expectExit" -eq 0 ];then
      echo "target's behavior"
    else
      echo 'compilation fails'
    fi
  )"
  printf '[%d] "%s"\tasserting %s\t' \
    $testNum "$(col blu "$(labelOfSource "$eqTestSrc")")" "$expectSummary" |
    tee -a "$suiteLog"

  # Derivative files we expect present
  local expected="$(pathToGenSib "$(
    if [ "$expectExit" -eq 0 ];then printf out; else printf err;fi
  )" "$eqTestSrc")";
  if ! [ -f "$expected" ];then
    printUnitResult $(unitTagFromExit 1) | tee -a "$suiteLog"
    printf \
      'BUG: cannot test without expecation file:\n\t%s\n' \
      "$expected" >> "$suiteLog"
    return 1
  fi

  # files we'll generate
  local eqTarget="$(ensureFirstSibling c "$eqTestSrc")"
  local eqTargetObj="$(ensureFirstSibling a "$eqTestSrc")"
  local compilerErrs="$(ensureFirstSibling stderr "$eqTestSrc")"
  local actual="$(ensureFirstSibling actual "$eqTestSrc")"
  local diffR="$(ensureFirstSibling diff "$eqTestSrc")"

  # Actually run test program
  "$eqCompiler" < "$eqTestSrc" > "$eqTarget" && actualExit=$? || actualExit=$?

  if [ "$actualExit" -eq "$expectExit" ]; then
    # EqEq compiler treated sample source as expected

    local left="$expected" right="$actual"
    if [ "$expectExit" -eq 0 ];then
      if ! cc "$eqTarget" -o "$eqTargetObj" 2>&1;then
        printf \
          "\tCRITICAL:\tEqEq's source test unexpectedly fails to compile!\n" \
          >> "$suiteLog"
          return 1
      fi

      # Run our compield test target (itself compiled with eqCompiler)
      "$eqTargetObj" > "$actual" 2>&1
    else
      right="$compilerErrs"
    fi

    diffFiles "$left" "$right" > "$diffR"
    printUnitResult "$(unitTagFromExit $?)" | tee -a "$suiteLog"
    if [ "$opt_verbose" -eq 1 ];then
      cat "$diffR"
    fi

    [ "$(wc -l < "$diffR")" -eq 0 ]; return $?
  else
    # EqEq compiler did opposite of what we expected with sample source

    printUnitResult $(unitTagFromExit 1) | tee -a "$suiteLog"
    if [ "$expectExit" -eq 0 ];then
      printf '\tEqEq source unexpectedly failed to compile\n' >> "$suiteLog"
    else
      printf '\tBad EqEq source compiled, but failure expected\n' >> "$suiteLog"
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
cleanGeneratedFiles
touch "$suiteLog"

# Print test suite outline
printf '\nRunning %s:\n\t%s\n\n' \
  "$(col blu "$(printf '%d tests' ${#testFiles[@]})")" \
  "$(printf '%s, ' "${testFiles[@]}")"

sincePreviousTestLine=1
testNum=0; numFails=0
for testFile in "${testFiles[@]}"; do
  if ! isTestPresent "$testFile";then
    printf 'WARNING:\tskipping missing or incomplete test:\t"%s"\n' "$testFile"
    continue;
  fi
  case "$(basename "$testFile")" in
    test-*.$srcExt) expectExit=0;;
    fail-*.$srcExt) expectExit=1;;
    *)
      printf 'WARNING:\tskipping UNKNOWN test:\t"%s"\n' "$testFile"
      continue
      ;;
  esac
  if [ "$testNum" -eq 0 ];then testNum=1;fi

  # Run test
  if ! CheckTest "$testFile" "$expectExit" "$testNum";then
    numFails=$(( numFails + 1 ))
  fi

  if [ "$opt_keep" -eq 0 ];then
    for genExt in "${genFileExts[@]}";do
      gen="$(dirname "$testFile")"/"$(labelOfSource "$testFile").${genExt}"
      rmIfExists "$gen" >/dev/null
    done
  fi

  # Verbose-printing of logs
  if [ "$opt_verbose" -eq 1 ];then
    sed -n "$(( ${sincePreviousTestLine} + 1 )),$"p "$suiteLog"
  fi

  testNum=$(( testNum + 1 ))
  sincePreviousTestLine="$(wc -l < "$suiteLog")"
done

# Print test suite summary
printf '\nSummary: '
if [ "$testNum" -eq 0 ];then
  col ylw 'SKIPPED\n'
elif [ "$numFails" -eq 0 ];then
  col grn 'PASSED\n'
else
  printf '%d of %s %s\n' "$numFails" "${#testFiles[@]}" "$(col red FAILED)"
fi
exit $anyFailures
