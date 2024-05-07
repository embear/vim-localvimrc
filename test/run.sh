#!/bin/bash

# setup some variables
BASEDIR=$(readlink -f "$(dirname $(dirname $0))")
LOCALVIMRC_TEST_BASE="$(mktemp -td localvimrc.XXXXXXXXXX)"
LOCALVIMRC_TEST_DIR="${LOCALVIMRC_TEST_BASE}/test"
export LOCALVIMRC_TEST_DIR

# get latest vader
if [ ! -s ${BASEDIR}/test/vader ]
then
  echo -n "getting vader ... "
  git clone --depth=1 https://github.com/junegunn/vader.vim.git ${BASEDIR}/test/vader >/dev/null 2>&1
  echo "DONE"
fi

# run the test
echo -n "running tests ... "
cd ${BASEDIR}/test
OUTPUT=$(vim --not-a-term -Nu <(cat << VIMRC
filetype off
set rtp+=${BASEDIR}
set rtp+=${BASEDIR}/test/vader
filetype plugin indent on
syntax enable
VIMRC
) -c "Vader! test_*.vader" 2>&1)
RC=$?

if [ ${RC} -ne 0 ]
then
  echo "[0;31mFAILED[0m"
  echo
  echo "${OUTPUT}"
else
  echo "DONE"
fi
# delete temporary directory
if [ -d "${LOCALVIMRC_TEST_BASE}" ]
then
  rm -rf ${LOCALVIMRC_TEST_BASE}
fi

exit ${RC}
