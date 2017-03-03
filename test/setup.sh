#!/bin/sh

TEST_DIRECTORY=/tmp/localvimrc_test

# go to temporary directory
rm -rf ${TEST_DIRECTORY}
mkdir -p ${TEST_DIRECTORY}
cd ${TEST_DIRECTORY}

# create test directory tree
DIR=.
for NEXT in a b c d e f
do
  DIR=${DIR}/${NEXT}
  mkdir -p ${DIR}
  cat >${DIR}/.lvimrc <<EOF
let g:localvimrc_test_var += [ "lvimrc: ${DIR}" ]
EOF
  cat >${DIR}/.localvimrc <<EOF
let g:localvimrc_test_var += [ "localvimrc: ${DIR}" ]
EOF
done
