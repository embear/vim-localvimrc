.PHONY: all doc

html2vimdoc = support/vim-tools/bin/html2vimdoc

all: doc

doc: doc/localvimrc.txt

$(html2vimdoc):
	@echo "#### building markdown to vim help converter ####"
	@support/build_vim-tools.sh

doc/localvimrc.txt: README.md $(html2vimdoc)
	@echo "#### converting README to vim documentation ####"
	@$(html2vimdoc) -f localvimrc $< >$@
