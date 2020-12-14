#!/bin/bash

#get displays running under my UUID

ps -u $(id -u) -o pid= |    \
  while read pid; do
    cat /proc/$pid/environ 2>/dev/null | \
    tr '\0' '\n' | \
    grep '^DISPLAY=:';
  done | \
  grep -o ':[0-9]*' | \
  sort -u
