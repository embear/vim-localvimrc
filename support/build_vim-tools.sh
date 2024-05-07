#!/bin/bash
# build local version of vim-tools

# package settings
PACKAGE=vim-tools
REPO="https://github.com/ycm-core/vim-tools"
HERE=$(readlink -f "$(dirname $0)")
DEST=$(readlink -f "${HERE}/vim-tools")

# die()
die()
{
  echo "[0;31m$@[0m" >&2
  exit 1
}

# get source code
if [ ! -s ${DEST} ]
then
  echo -n "getting vim-tools ... "
  git clone --depth=1 "${REPO}" "${DEST}" >/dev/null 2>&1 || die "FAILED"
  echo "DONE"
fi

# virtualenv
echo -n "creating virtualenv ... "
virtualenv ${DEST}/virtualenv >/dev/null 2>&1 || die "FAILED"
${DEST}/virtualenv/bin/pip install -r ${DEST}/requirements.txt >/dev/null 2>&1 || die "FAILED"
echo "DONE"

# executable
mkdir ${DEST}/bin
cat > ${DEST}/bin/html2vimdoc <<EOF
#!/bin/sh
. ${DEST}/virtualenv/bin/activate >/dev/null 2>&1
${DEST}/html2vimdoc.py \$*
EOF
chmod 0755 ${DEST}/bin/html2vimdoc
