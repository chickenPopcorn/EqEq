#!/usr/bin/env bash
set -e
set -x
declare -r thisdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
declare -r lrm="$(readlink -f "$thisdir"/../language-reference-manual.md)"
sed 's|^#|##|' "$lrm" 
