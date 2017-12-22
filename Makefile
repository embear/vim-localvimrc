doc/localvimrc.txt: README.md
	html2vimdoc -f localvimrc README.md >$@
