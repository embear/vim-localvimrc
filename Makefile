.PHONY: all clean doc package test

vim-tools = support/vim-tools
html2vimdoc = $(vim-tools)/bin/html2vimdoc

all: doc package

clean:
	@echo "#### purging markdown to vim help converter ####"
	@rm -rf $(vim-tools)

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

test:
	@echo "#### running tests ####"
	@test/run.sh

$(html2vimdoc):
	@echo "#### building markdown to vim help converter ####"
	@support/build_vim-tools.sh

doc/localvimrc.txt: README.md $(html2vimdoc)
	@echo "#### converting README to vim documentation ####"
	@$(html2vimdoc) -f localvimrc $< >$@
