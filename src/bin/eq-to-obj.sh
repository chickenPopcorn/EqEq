#!/usr/bin/env bash
set -e

declare -r eqSrc="$1"
if [ ! -f "$eqSrc" ];then
  printf 'EqualsEquals source not found at:\n\t"%s"\n' "$eqSrc" >&2
  exit 1
fi

# Allow -l args to be overridden
mathLib=-lm # default
for arg in ${@}; do
  case "$arg" in
    -l*) mathLib='';;
  esac
done

${CC:-cc} $@ "$mathLib"
