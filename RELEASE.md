# Create a release

  1. Update changelog in `README.md`
  2. Update version in `plugin/localvimrc.vim`
  3. Convert `README.md` to help file: `html2vimdoc -f localvimrc README.md >doc/localvimrc.txt`
  4. Commit current version: `hg commit -m 'prepare release vX.Y.Z'`
  5. Tag version: `hg tag vX.Y.Z -m 'tag release vX.Y.Z'`
  6. Push release to [Bitbucket] and [GitHub]:
    - `hg push ssh://hg@bitbucket.org/embear/localvimrc`
    - `hg push git+ssh://git@github.com:embear/vim-localvimrc.git`
  7. Create a Vimball archive: `hg locate -X 'test/' -X '\.*' -X README.md -X RELEASE.md | vim -C -c '%MkVimball! localvimrc .' -c 'q!' -`
  8. Update [VIM online]

[Bitbucket]: https://bitbucket.org/embear/localvimrc
[GitHub]: https://github.com/embear/vim-localvimrc
[VIM online]: http://www.vim.org/scripts/script.php?script_id=441
