.PHONY: all clean doc package test

sources = plugin/localvimrc.vim
helpfile = doc/localvimrc.txt
vimball = localvimrc.vmb
vim-tools = support/vim-tools
html2vimdoc = $(vim-tools)/bin/html2vimdoc

all: doc package

clean:
	@echo "#### purging markdown to vim help converter ####"
	@rm -rf $(vim-tools)
	@echo "#### purging vimball ####"
	@rm -rf $(vimball)

doc: $(helpfile)

package: $(vimball)

test:
	@echo "#### running tests ####"
	@test/run.sh

$(html2vimdoc):
	@echo "#### building markdown to vim help converter ####"
	@support/build_vim-tools.sh

$(helpfile): README.md $(html2vimdoc)
	@echo "#### converting README to vim documentation ####"
	@$(html2vimdoc) -f $$(basename $@ .txt) $< >$@

$(vimball): LICENSE $(helpfile) $(sources)
	@echo "#### creating vimball package ####"
	@for FILE in $^; do echo $${FILE}; done \
		| vim -C --not-a-term -c '%%MkVimball! localvimrc .' -c 'q!' -
