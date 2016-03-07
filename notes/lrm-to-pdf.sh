#!/usr/bin/env bash
#
# Converts LRM doc to PDF including a table of contents.

USE_PANDOC=1 # toggle this as `1` or `0` without quotes

set -e
declare -r lrmToPdfDir="$(mktemp --directory --tmpdir  "$(basename "$0")"_XXXXXX.d)"
declare -r srcLrm="$(printf '%s/%s' "$(git rev-parse --show-toplevel)" notes/language-reference-manual.md)"

cleanup() { [ -d "$lrmToPdfDir" ] && rm -rf "$lrmToPdfDir"; }
trap cleanup SIGINT

cd "$lrmToPdfDir"

getExecPath() {
  local execName="$1"
  local localExecPath="$2"

  local path; path="$(readlink -f "$(type -p "$execName")")"
  if [ $? -ne 0 ];then
    printf 'WARNING: downloading local copy of `%s`\n' "$execName" >&2
    npm install "$execName" >/dev/null 2>&1
    path="$localExecPath"
  fi

  echo "$path"; [ -x "$path" ]
}
docTocExec="$(getExecPath doctoc node_modules/doctoc/doctoc.js)"
markedExec="$(getExecPath marked node_modules/marked/bin/marked)"

# <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.4.1/prism.min.js"></script>
#
# <script src="https://cdnjs.cloudflare.com/ajax/libs/prettify/r298/prettify.min.js"></script>
#
# <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.2.0/highlight.min.js"></script>
# <script>hljs.initHighlightingOnLoad();</script>
cat > ./lrm.html <<-EOF_STYLES
<style type="text/css">
  @font-face {
    font-family: LiberationSerif;
    src: url('file:///usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf');
  }
  body, p, h1, h2, h3, h4, h5, h6 { font-family: serif; }
  body {
    padding: 7em;
    font-family: serif;
    font-size: 21pt;
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
#uncomment if using base64 embedded @font-face approach
# fontBase64="$(base64  /usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf | tr '\n' ' ' | sed -e 's| ||g' )"
# set -i "s|BASE64_FONT|$fontBase64|" ./lrm.html

lrmPdf="$(mktemp --tmpdir="$(dirname "$srcLrm")" lrm_XXXXXXXX.pdf)"

# Step 1: Inject table of contents
cp "$srcLrm" ./lrm.md
"$docTocExec" --notitle --github ./lrm.md >/dev/null

# Step 2: Convert to Markdown PDF
if [ $USE_PANDOC -gt 0 ];then
  pandoc --read=markdown_github --output="$lrmPdf" < ./lrm.md
else
  # Step 2 in 2 parts: markdown-to-html, html-to-pdf

  "$markedExec" < ./lrm.md >> ./lrm.html
  wkhtmltopdf \
    --page-size A4 \
    --margin-bottom 20mm \
    --margin-top 20mm \
    --enable-javascript  \
    --quiet  \
    ./lrm.html "$lrmPdf"
fi

printf '%s\n' "$lrmPdf"

cleanup
