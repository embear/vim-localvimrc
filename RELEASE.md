# Create a release

  1. Run unit tests: `make test`
  2. Update changelog in `README.md`
  3. Update version in `plugin/localvimrc.vim`
  4. Convert `README.md` to help file: `make doc`
  5. Commit current version: `hg commit -m 'prepare release vX.Y.Z'`
  6. Tag version: `hg tag vX.Y.Z -m 'tag release vX.Y.Z'`
  7. Push release to [GitHub]:
    - `hg push git+ssh://git@github.com:embear/vim-localvimrc.git`
  8. Create a Vimball archive: `make package`
  9. Update [VIM online]

[GitHub]: https://github.com/embear/vim-localvimrc
[VIM online]: http://www.vim.org/scripts/script.php?script_id=441
