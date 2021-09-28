#!/bin/bash

# the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# the temp directory used, within $DIR
# omit the -p parameter to create a temporal directory in the default location
WORK_DIR=`mktemp -d -p "$DIR"`

# check if tmp dir was created
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

function alldone {      
  echo "The files were downloaded to $WORK_DIR"
}

# register the alldone function to be called on the EXIT signal
trap alldone EXIT

cd $WORK_DIR
wget `curl -s https://api.github.com/repos/zynthbox/zynthian-quick-components/releases/latest | grep "browser_download_url.*.deb*" | cut -d : -f 2,3 | tr -d \" | xargs`
wget `curl -s https://api.github.com/repos/zynthbox/libzl/releases/latest | grep "browser_download_url.*.deb*" | cut -d : -f 2,3 | tr -d \" | xargs`
dpkg --install zynthian-quick-components* libzl*
cd $DIR
