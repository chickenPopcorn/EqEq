#!/usr/bin/env bash
#
# Converts LRM doc to PDF including a table of contents.

USE_PANDOC=0 # toggle this as `1` or `0` without quotes

set -e
declare -r lrmToPdfDir="$(mktemp --directory --tmpdir  "$(basename "$0")"_XXXXXX.d)"
declare -r srcDir="$(git rev-parse --show-toplevel)"
declare -r srcLrm="$(printf '%s/%s' "$srcDir" notes/language-reference-manual.md)"

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

printCustomWebDev() {
  # <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.4.1/prism.min.js"></script>
  #
  # <script src="https://cdnjs.cloudflare.com/ajax/libs/prettify/r298/prettify.min.js"></script>
  #
  # <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.2.0/highlight.min.js"></script>
  # <script>hljs.initHighlightingOnLoad();</script>

  cat <<-EOF_STYLES
  <style type="text/css">
    body {
      padding: 4em;
      font-family: "Latin Modern Roman", LiberationSerif, serif;
      font-size: 12pt;
    }
    #toc,
    body > ul:first-of-type {
      margin: 1.5em auto 6em auto;
    }
    #toc a,
    body > ul:first-of-type a {
      text-decoration: none;
      color: inherit;
    }
    h1:nth-of-type(1) {
      text-align: center;
      margin: 2em 0 1em 0;
    }
    a {
      /** since we're not inserting foot-notes, this is just strange */
      text-decoration: none;
      color: inherit;
    }
    pre, code { white-space: pre; }
    pre { padding: 1em 0 1em 1ex; }
    code { font-size:.7em; }
    pre > code.hljs, pre > code, pre { background-color: #FFF8E8; }
    p { line-height: 1.25em; }
    table:nth-of-type(1),
    #authors table {
      margin: 1em auto;
      text-align: left;
      width: 100%;
      font-size:.85em;
    }
    table:nth-of-type(1) thead { border-bottom: 1px solid grey; }
  </style>
  <script>
  'use strict';
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
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.2.0/styles/default.min.css">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/9.2.0/highlight.min.js"></script>
  <script>hljs.initHighlightingOnLoad();</script>
EOF_STYLES
}

#uncomment if using base64 embedded @font-face approach
# fontBase64="$(base64  /usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf | tr '\n' ' ' | sed -e 's| ||g' )"
# set -i "s|BASE64_FONT|$fontBase64|" ./lrm.html

injectToc() {
  "$docTocExec" \
    --title='<h1>EqualsEquals Language Reference Manual</h1>' \
    --github \
    ./lrm.md >/dev/null
}

lrmPdf="$(mktemp --tmpdir="$(dirname "$srcLrm")" lrm_XXXXXXXX.pdf)"

cp "$srcLrm" ./lrm.md

if [ $USE_PANDOC -gt 0 ];then
  injectToc ./lrm.md
  pandoc --read=markdown_github --output="$lrmPdf" < ./lrm.md
else
  injectToc ./lrm.md

  "$markedExec" < ./lrm.md >> ./lrm.html.orig

  printCustomWebDev > lrm.html

  # Step 0.5: Inject authors table:
  declare -r titleLnNum="$(grep --line-number '^<h1>EqualsEquals' ./lrm.md | sed -e 's|^\([0-9]*\):.*$|\1|')"
  sed -n "1,${titleLnNum}p" ./lrm.html.orig >> lrm.html
  grep '^|' "$srcDir"/README.md  |
    sed -e 's/\(^|.*|.*|.*|.*\)|.*$/\1/' |
    "$markedExec" >> ./lrm.html
  sed -n "$(( titleLnNum + 1  )),\$p" ./lrm.html.orig >> lrm.html

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
