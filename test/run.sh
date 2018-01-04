#!/bin/sh

# setup some variables
SCRIPT_DIR="$(dirname $0)"
SCRIPT_NAME="$(basename $0)"
LOCALVIMRC_TEST_BASE="$(mktemp -td localvimrc.XXXXXXXXXX)"
LOCALVIMRC_TEST_DIR="${LOCALVIMRC_TEST_BASE}/test"
export LOCALVIMRC_TEST_DIR

# go to script directory
cd ${SCRIPT_DIR}

# run the test
vim -Nu vimrc -c "Vader! test_*.vader"

# delete temporary directory
if [ -d "${LOCALVIMRC_TEST_BASE}" ]
then
  rm -rf ${LOCALVIMRC_TEST_BASE}
fi
