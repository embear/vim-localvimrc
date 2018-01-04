#!/bin/sh

TEST_DIR="/tmp/localvimrc/test"
if [ $# -eq 1 ]
then
  if [ -d "$(dirname $1)" ]
  then
    TEST_DIR="$1"
  fi
fi

# go to temporary directory
rm -rf ${TEST_DIR}
mkdir -p ${TEST_DIR}
cd ${TEST_DIR}

# create test directory tree
DIR=.
for NEXT in a b c d e f
do
  DIR=${DIR}/${NEXT}
  mkdir -p ${DIR}
  cat >${DIR}/.lvimrc <<EOF
if !exists("g:localvimrc_test_var")
  let g:localvimrc_test_var = []
endif
let g:localvimrc_test_var += [ "lvimrc: ${DIR}" ]
EOF
  cat >${DIR}/.localvimrc <<EOF
if !exists("g:localvimrc_test_var")
  let g:localvimrc_test_var = []
endif
let g:localvimrc_test_var += [ "localvimrc: ${DIR}" ]
EOF
done
