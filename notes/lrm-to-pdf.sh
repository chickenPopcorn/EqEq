#!/usr/bin/env bash
#
# Converts LRM doc to PDF including a table of contents.

set -e
declare -r lrmToPdfDir="$(mktemp --directory --tmpdir  "$(basename "$0")"_XXXXXX.d)"
declare -r srcLrm="$(printf '%s/%s' "$(git rev-parse --show-toplevel)" notes/language-reference-manual.md)"

cleanup() { [ -d "$lrmToPdfDir" ] && rm -rf "$lrmToPdfDir"; }
trap cleanup SIGINT

cd "$lrmToPdfDir"

npm install doctoc marked > /dev/null 2>&1
docTocExec="$(readlink -f node_modules/doctoc/doctoc.js)"; [ -x "$docTocExec" ]
markedExec="$(readlink -f node_modules/marked/bin/marked)"; [ -x "$markedExec" ]

# <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.4.1/prism.min.js"></script>
#
# <script src="https://cdnjs.cloudflare.com/ajax/libs/prettify/r298/prettify.min.js"></script>
#
# <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.2.0/highlight.min.js"></script>
# <script>hljs.initHighlightingOnLoad();</script>
cat > ./lrm.html <<-EOF_STYLES
<style type="text/css">
  body {
    padding: 5em;
    font-family: serif;
  }
  h1:nth-of-type(1) { text-align: center; }
</style>
<script>
window.onload = function() {
  var codes = document.querySelectorAll('code');
  for (let idx in codes) {
    var node = codes[idx];
    if (!node || !node.getAttribute) { continue; }
    var lang = (node.getAttribute('class') || '').match(/lang-(\w*)/);
    if (!(lang && lang.length && lang[1])) { continue; }

    lang = lang[1];
    node.setAttribute(
        'class',
        node.getAttribute('class') + ' ' + lang);
  }
}
</script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.2.0/highlight.min.js"></script>
<script>hljs.initHighlightingOnLoad();</script>
EOF_STYLES

cp -v "$srcLrm" ./lrm.md
"$docTocExec" --notitle --github ./lrm.md
"$markedExec" < ./lrm.md >> ./lrm.html

lrmPdf="$(mktemp --tmpdir="$(dirname "$srcLrm")" lrm_XXXXXXXX.pdf)"
wkhtmltopdf  ./lrm.html "$lrmPdf"
printf 'PDF of LRM generated beside markdown, here:\n\t%s\n' "$lrmPdf"

cleanup
