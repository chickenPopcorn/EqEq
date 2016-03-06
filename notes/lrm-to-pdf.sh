#!/usr/bin/env bash
#
# Converts LRM doc to PDF including a table of contents.

set -e
declare -r lrmToPdfDir="$(mktemp --tmpdir  "$(basename "$0")"_XXXXXX.d)"
declare -r srcLrm="$("$(git rev-parse --show-toplevel)"/notes/language-reference-manual.md)"

cleanup() { [ -d "$lrmToPdfDir" ] && rm -rf "$lrmToPdfDir"; }
trap cleanup SIGINT

cd "$lrmToPdfDir"

npm install marked >/dev/null 2>&1
docTocExec="$(readlink -f node_modules/doctoc/doctoc.js)"; [ -x "$docTocExec" ]

npm install marked >/dev/null 2>&1
markedExec="$(readlink -f node_modules/marked/bin/marked)"; [ -x "$markedExec" ]

cp -v "$srcLrm" ./lrm.md
"$docTocExec" --title 'EqualsEquals (aka "eqeq")' --github ./lrm.md
"$markedExec" < ./lrm.md > ./lrm.html

lrmPdf="$(mktemp --tmpdir="$(dirname "$srcLrm")" lrm_XXXXXXXX.pdf)"
wkhtmltopdf  ./lrm.html "$lrmPdf"
printf 'PDF of LRM generated beside markdown, here:\n\t%s\n' "$lrmPdf"

cleanup
