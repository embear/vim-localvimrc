For Vim version 7.4    Last change: 2014 February 6

* [Description](#localvimrc-description)
* [Commands](#localvimrc-commands)
* [Variables](#localvimrc-variables)
* [Settings](#localvimrc-settings)
* [Contribute](#localvimrc-contribute)
* [Credits](#localvimrc-credits)

<a name="localvimrc-description"></a>
DESCRIPTION
===========

This plugin searches for local vimrc files in the file system tree of the currently opened file. It searches for all `.lvimrc` files from the directory of the file up to the root directory. By default those files are loaded in order from the root directory to the directory of the file. The filename and amount of loaded files are customizable through global variables.

For security reasons it the plugin asks for confirmation before loading a local vimrc file and loads it using `:sandbox` command. The plugin asks once per session and local vimrc before loading it, if the file didn't change since previous loading.

It is possible to define a whitelist and a blacklist of local vimrc files that are loaded or ignored unconditionally.

<a name="localvimrc-commands"></a>
COMMANDS
========

### LocalVimRCClear

Clear all stored decisions made in the past, when the plugin asked about sourcing a local vimrc file.

<a name="localvimrc-variables"></a>
VARIABLES
=========

The plugin provides several convenience variables to make it easier to set up path dependent setting like for example makeprg. Adding the following lines to a local vimrc in the root directory of a project modify the behavior of `:make` to change into a build directory and call make there:

```language-viml
let &l:makeprg="cd ".g:localvimrc_script_dir."/build && make"
```

> NOTE: This is only possible if you disable sandbox mode.

Other variables provide a way to prevent multiple execution of commands. They can be used to implement guards:

```language-viml
" do stuff you want to do on every buffer enter event

" guard to end loading if it has been loaded for the currently edited file
if g:localvimrc_sourced_once_for_file
  finish
endif

" do stuff you want to do only once for a edited file

" guard to end loading if it has been loaded for the running vim instance
if g:localvimrc_sourced_once
  finish
endif

" do stuff you want to do only once for a running vim instance
```

---
`g:localvimrc_file`

Fully qualified file name of file that triggered loading the local vimrc file.

---
`g:localvimrc_file_dir`

Fully qualified directory of file that triggered loading the local vimrc file.

---
`g:localvimrc_script`

Fully qualified file name of the currently loaded local vimrc file.

---
`g:localvimrc_script_dir`

Fully qualified directory of the currently loaded local vimrc file.

---
`g:localvimrc_sourced_once`

Set to `1` if the currently loaded local vimrc file had already been loaded in this session. Set to `0` otherwise.

---
`g:localvimrc_sourced_once_for_file`

Set to `1` if the currently loaded local vimrc file had already been loaded in this session for the currently edited file. Set to `0` otherwise.

<a name="localvimrc-settings"></a>
SETTINGS
========

Use:

```language-viml
let g:option_name=option_value
```

to set them in your global vimrc.

---
`g:localvimrc_name`

List of filenames of local vimrc files. The given name can include a directory name such as `.config/localvimrc`.

Previous versions of localvimrc only supported a single file as string. This is still supported for backward compatibility.

Default: `[ ".lvimrc" ]`

---
`g:localvimrc_event`

List of autocommand events that trigger local vimrc file loading.

Default: `[ "BufWinEnter" ]`

> NOTE: BufWinEnter is the default to enable lines like
>
> ```language-viml
> setlocal colorcolumn=+1
> ```
>
> in the local vimrc file. Settings "local to window" need to be set for every time a buffer is displayed in a window.

---
`g:localvimrc_reverse`

Reverse behavior of loading local vimrc files.

* `0` - Load files in order from root directory to directory of the file.
* `1` - Load files in order from directory of the file to root directory.

Default: `0`

---
`g:localvimrc_count`

On the way from root, the last `localvimrc_count` files are sourced.

Default: `-1` (all)

---
`g:localvimrc_sandbox`

Source the found local vimrc files in a sandbox for security reasons.

* `0` - Don't load vimrc file in a sandbox.
* `1` - Load vimrc file in a sandbox.

Default: `1`

---
`g:localvimrc_ask`

Ask before sourcing any local vimrc file. In a vim session the question is only asked once as long as the local vimrc file has not been changed.

* `0` - Don't ask before loading a vimrc file.
* `1` - Ask before loading a vimrc file.

Default: `1`

---
`g:localvimrc_persistent`

Make the decisions given when asked before sourcing local vimrc files persistent over multiple vim runs and instances. The decisions are written to the file defined by and `g:localvimrc_persistence_file`.

* `0` - Don't store and restore any decisions.
* `1` - Store and restore decisions only if the answer was given in upper case (Y/N/A).
* `2` - Store and restore all decisions.

Default: `0`

---
`g:localvimrc_persistence_file`

Filename used for storing persistent decisions made when asked before sourcing local vimrc files.

Default:

* `$HOME/.localvimrc_persistent` on Unix
* `$HOME/_localvimrc_persistent` on MS-Windows

---
`g:localvimrc_whitelist`

If a local vimrc file matches the regular expression given by `g:localvimrc_whitelist` this file is loaded unconditionally.

Files matching `g:localvimrc_whitelist` are sourced even if they are matched by `g:localvimrc_blacklist`.

See `regular-expression` for patterns that are accepted.

Example:

```language-viml
" whitelist all local vimrc files in users project foo and bar
let g:localvimrc_whitelist='/home/user/projects/\(foo\|bar\)/.*'
```

Default:  No whitelist

---
`g:localvimrc_blacklist`

If a local vimrc file matches the regular expression given by `g:localvimrc_blacklist` this file is skipped unconditionally.

Files matching `g:localvimrc_whitelist` are sourced even if they are matched by `g:localvimrc_blacklist`.

See `regular-expression` for patterns that are accepted.

Example:

```language-viml
" blacklist all local vimrc files in shared project directory
let g:localvimrc_whitelist='/share/projects/.*'
```

Default:  No blacklist

---
`g:localvimrc_debug`

Debug level for this script.

Default: `0`

<a name="localvimrc-contribute"></a>
CONTRIBUTE
==========

To contact the author (Markus Braun), please email: markus.braun@krawel.de

If you think this plugin could be improved, fork on GitHub and send a pull request or just tell me your ideas.

Bitbucket: https://bitbucket.org/embear/localvimrc
GitHub:    https://github.com/embear/vim-localvimrc

<a name="localvimrc-credits"></a>
CREDITS
=======

- Simon Howard for his hint about "sandbox"
- Mark Weber for the idea of using checksums
- Daniel Hahler for various patches
- Justin M. Keyes for ideas to improve this plugin
