#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

if ! command -v black &> /dev/null; then
  echo "Python formatter 'black' not found"
  echo "Install 'black' and run the script again : sudo pip install black"
  exit 1
fi

if ! command -v watchmedo &> /dev/null; then
  echo "Python 'watchdog' module not found"
  echo "Install 'watchdog' and run the script again : sudo pip install \"watchdog[watchmedo]\""
  exit 1
fi

echo "Watching for changes in dir : $SCRIPTPATH"
echo

(
  cd "$SCRIPTPATH"
  
  watchmedo \
    shell-command \
    --ignore-directories \
    --patterns="*.py" \
    --recursive \
    --command='echo "Formatting file : ${watch_src_path}"; black -q -l 79 "${watch_src_path}"'
)
