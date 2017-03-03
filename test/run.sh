#!/bin/sh

# setup some variables
SCRIPT_DIR="$(dirname $0)"
SCRIPT_NAME="$(basename $0)"

# go to script directory
cd ${SCRIPT_DIR}

# run the tests
vim -Nu vimrc -c "Vader! test_*.vader"
