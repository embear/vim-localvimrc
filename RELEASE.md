# Create a release

  1. Update Changelog in `README.md`
  2. Convert `README.md` to help file: `html2vimdoc -f localvimrc README.md >doc/localvimrc.txt`
  3. Commit current version: `hg commit -m 'prepare release vX.Y.Z'`
  4. Tag version: `hg tag vX.Y.Z -m 'tag release vX.Y.Z'`
  5. Push release to [Bitbucket] and [GitHub]:
    - `hg push ssh://hg@bitbucket.org/embear/localvimrc`
    - `hg push git+ssh://git@github.com:embear/vim-localvimrc.git`
  6. Create a Vimball archive: `hg locate | vim -C -c '%MkVimball! localvimrc .' -c 'q!' -`
  7. Update [VIM online]

[Bitbucket]: https://bitbucket.org/embear/localvimrc
[GitHub]: https://github.com/embear/vim-localvimrc
[VIM online]: http://www.vim.org/scripts/script.php?script_id=441
