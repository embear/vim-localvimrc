# Create a release

  1. Run unit tests: `make test`
  2. Update changelog in `README.md`
  3. Update version in `plugin/localvimrc.vim`
  4. Convert `README.md` to help file: `make doc`
  5. Commit current version: `git commit -m 'prepare release vX.Y.Z'`
  6. Tag version: `git tag vX.Y.Z -m 'tag release vX.Y.Z' -s`
  7. Push release to [GitHub]:
    - `git push git@github.com:embear/vim-localvimrc.git`
    - `git push --tags git@github.com:embear/vim-localvimrc.git`
  8. Create a Vimball archive: `make package`
  9. Create a release on [VIM online] and [GitHub]

[GitHub]: https://github.com/embear/vim-localvimrc
[VIM online]: http://www.vim.org/scripts/script.php?script_id=441
