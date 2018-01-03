.PHONY: all doc package

html2vimdoc = support/vim-tools/bin/html2vimdoc

all: doc package

doc: doc/localvimrc.txt

package:
	@echo "#### creating vimball package ####"
	@hg locate       \
	  -X 'test/'    \
	  -X 'support/' \
	  -X '\.*'      \
	  -X README.md  \
	  -X RELEASE.md \
	  -X Makefile   \
	  | vim -C --not-a-term -c '%%MkVimball! localvimrc .' -c 'q!' -

$(html2vimdoc):
	@echo "#### building markdown to vim help converter ####"
	@support/build_vim-tools.sh

doc/localvimrc.txt: README.md $(html2vimdoc)
	@echo "#### converting README to vim documentation ####"
	@$(html2vimdoc) -f localvimrc $< >$@
