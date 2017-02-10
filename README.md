# Localvimrc

This plugin searches for local vimrc files in the file system tree of the
currently opened file. It searches for all ".lvimrc" files from the directory
of the file up to the root directory. By default those files are loaded in
order from the root directory to the directory of the file. The filename and
amount of loaded files are customizable through global variables.

For security reasons it the plugin asks for confirmation before loading a
local vimrc file and loads it using |:sandbox| command. The plugin asks once
per session and local vimrc before loading it, if the file didn't change since
previous loading.

It is possible to define a whitelist and a blacklist of local vimrc files that
are loaded or ignored unconditionally.

The plugin can be found on [Bitbucket], [GitHub] and [VIM online].

## Commands

### The `LocalVimRC` command

Resource all local vimrc files for the current buffer.

### The `LocalVimRCClear` command

Clear all stored decisions made in the past, when the plugin asked about
sourcing a local vimrc file.

## Variables

The plugin provides several convenience variables to make it easier to set up
path dependent setting like for example makeprg. These variables are only
available inside your local vimrc file because they are only unambiguous there.

Adding the following lines to a local vimrc in the root directory of a project
modify the behavior of |:make| to change into a build directory and call make
there:

``` {.vim}
let &l:makeprg="cd ".g:localvimrc_script_dir_unresolved."/build && make"
```

------------------------------------------------------------

**NOTE:**

This is only possible if you disable sandbox mode.

------------------------------------------------------------

Other variables provide a way to prevent multiple execution of commands. They
can be used to implement guards:

``` {.vim}
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

### The `g:localvimrc_file` variable

Fully qualified file name of file that triggered loading the local vimrc file.

### The `g:localvimrc_file_dir` variable

Fully qualified directory of file that triggered loading the local vimrc file.

### The `g:localvimrc_script` variable

Fully qualified and resolved file name of the currently loaded local vimrc
file.

### The `g:localvimrc_script_dir` variable

Fully qualified and resolved directory of the currently loaded local vimrc
file.

### The `g:localvimrc_script_unresolved` variable

Fully qualified but unresolved file name of the currently loaded local vimrc
file.

### The `g:localvimrc_script_dir_unresolved` variable

Fully qualified but unresolved directory of the currently loaded local vimrc
file.

### The `g:localvimrc_sourced_once` variable

Set to `1` if the currently loaded local vimrc file had already been loaded in
this session. Set to `0` otherwise.

### The `g:localvimrc_sourced_once_for_file` setting

Set to `1` if the currently loaded local vimrc file had already been loaded in
this session for the currently edited file. Set to `0` otherwise.

## Settings

To change settings from their default add  similar line to your global |vimrc| file.

``` {.vim}
let g:option_name=option_value
```

### The `g:localvimrc_name` setting

List of filenames of local vimrc files. The given name can include a directory
name such as ".config/localvimrc".

Previous versions of localvimrc only supported a single file as string. This
is still supported for backward compatibility.

  - Default: `[ ".lvimrc" ]`

### The `g:localvimrc_event` setting

List of autocommand events that trigger local vimrc file loading.

  - Default: `[ "BufWinEnter" ]`

------------------------------------------------------------

**NOTE:**

BufWinEnter is the default to enable lines like

``` {.vim}
setlocal colorcolumn=+1
```

in the local vimrc file. Settings "local to window" need to be set for
every time a buffer is displayed in a window.

------------------------------------------------------------

### The `g:localvimrc_reverse` setting

Reverse behavior of loading local vimrc files.

  - Value `0`: Load files in order from root directory to directory of the file.
  - Value `1`: Load files in order from directory of the file to root directory.
  - Default: `0`

### The `g:localvimrc_count` setting

On the way from root, the last localvimrc_count files are sourced.

  - Default: `-1` (all)

### The `g:localvimrc_sandbox` setting

Source the found local vimrc files in a sandbox for security reasons.

  - Value `0`: Don't load vimrc file in a sandbox.
  - Value `1`: Load vimrc file in a sandbox.
  - Default: `1`

### The `g:localvimrc_ask` setting

Ask before sourcing any local vimrc file. In a vim session the question is
only asked once as long as the local vimrc file has not been changed.

  - Value `0`: Don't ask before loading a vimrc file.
  - Value `1`: Ask before loading a vimrc file.
  - Default: `1`

### The `g:localvimrc_persistent` setting

Make the decisions given when asked before sourcing local vimrc files
persistent over multiple vim runs and instances. The decisions are written to
the file defined by and |g:localvimrc_persistence_file|.

  - Value `0`: Don't store and restore any decisions.
  - Value `1`: Store and restore decisions only if the answer was given in upper case (Y/N/A).
  - Value `2`: Store and restore all decisions.
  - Default: `0`

### The `g:localvimrc_persistence_file` setting

Filename used for storing persistent decisions made when asked before sourcing
local vimrc files.

  - Default (_Unix_):    "$HOME/.localvimrc_persistent"
  - Default (_Windows_): "$HOME/_localvimrc_persistent"

### The `g:localvimrc_whitelist` setting

If a local vimrc file matches the regular expression given by
|g:localvimrc_whitelist| this file is loaded unconditionally.

Files matching |g:localvimrc_whitelist| are sourced even if they are matched
by |g:localvimrc_blacklist|.

See |regular-expression| for patterns that are accepted.

Example:

``` {.vim}
" whitelist all local vimrc files in users project foo and bar
let g:localvimrc_whitelist='/home/user/projects/\(foo\|bar\)/.*'

" whitelist can also use lists of patterns
let g:localvimrc_whitelist=['/home/user/project1/', '/opt/project2/', '/usr/local/projects/vim-[^/]*/']
```

  - Default: No whitelist

### The `g:localvimrc_blacklist` setting

If a local vimrc file matches the regular expression given by
|g:localvimrc_blacklist| this file is skipped unconditionally.

Files matching |g:localvimrc_whitelist| are sourced even if they are matched by
|g:localvimrc_blacklist|.

See |regular-expression| for patterns that are accepted.

Example:

``` {.vim}
" blacklist all local vimrc files in shared project directory
let g:localvimrc_blacklist='/share/projects/.*'

" blacklist can also use lists of patterns
let g:localvimrc_blacklist=['/share/projects/.*', '/usr/share/other-projects/.*']
```

  - Default: No blacklist

### The `g:localvimrc_autocmd` setting

Emit autocommands |LocalVimRCPre| before and |LocalVimRCPost| after sourcing
every local vimrc file.

  - Default: `1`

### The `g:localvimrc_disable_upward_search` setting

The plugin searches for `g:localvimrc_name` file from the directory of the current file up to the root directory.
Set this option to `1` to disable upward search. If set to `1` plugin searches only in the file directory.

  - Default: `0`

### The `g:localvimrc_debug` setting

Debug level for this script.

  - Default: `0`

## Autocommands

If enabled localvimrc emits autocommands before and after sourcing an local vimrc file.

### The `LocalVimRCPre` autocommand

This autocommand is emitted right before sourcing each local vimrc file.

### The `LocalVimRCPost` autocommand

This autocommands is emitted right after sourcing each local vimrc file.

## Contribute

To contact the author (Markus Braun), please send an email to <markus.braun@krawel.de>

If you think this plugin could be improved, fork on [Bitbucket] or [GitHub] and
send a pull request or just tell me your ideas.

## Credits

- Simon Howard for his hint about "sandbox"
- Mark Weber for the idea of using checksums
- Daniel Hahler for various patches
- Justin M. Keyes for ideas to improve this plugin
- Lars Winderling for whitelist/blacklist patch
- Michon van Dooren for autocommands patch

## Changelog

vX.X.X : XXXX-XX-XX

  - |g:localvimrc_whitelist| and |g:localvimrc_blacklist| now takes optionally a list of regular expressions.
  - add convenience variables |g:localvimrc_script_unresolved| and |g:localvimrc_script_dir_unresolved|.
  - add ability to view local vimrc before sourcing when |g:localvimrc_ask| is enabled.
  - emit autocommands before and after sourcing files.

v2.4.0 : 2016-02-05

  - add setting |g:localvimrc_event| which defines the autocommand events that trigger local vimrc file loading.
  - don't lose persistence file on full partitions.
  - make it possible to supply a list of local vimrc filenames in |g:localvimrc_name|.
  - ask user when sourcing local vimrc fails and |g:localvimrc_sandbox| and |g:localvimrc_ask| is set whether the file should be sourced without sandbox.
  - fix a bug where local vimrc files are sourced in wrong order when some of them are symlinks to a different directory.

v2.3.0 : 2014-02-06

  - private persistence file to enable persistence over concurrent vim instances.
  - add convenience variables |g:localvimrc_sourced_once| and |g:localvimrc_sourced_once_for_file|.

v2.2.0 : 2013-11-09

  - remove redraw calls for better performance and fixing a bug on windows.
  - load local vimrc on event BufWinEnter to fix a bug with window local settings.
  - add |g:localvimrc_reverse| to change order of sourcing local vimrc files.
  - add convenience variables |g:localvimrc_file|, |g:localvimrc_file_dir|, |g:localvimrc_script| and |g:localvimrc_script_dir|.

v2.1.0 : 2012-09-25

  - add possibility to make decisions persistent.
  - use full file path when storing decisions.

v2.0.0 : 2012-04-05

  - added |g:localvimrc_whitelist| and |g:localvimrc_blacklist| settings.
  - ask only once per session and local vimrc before loading it, if it didn't change.

v2758 : 2009-05-11

  - source .lvimrc in a sandbox to better maintain security, configurable using |g:localvimrc_sandbox|.
  - ask user before sourcing any local vimrc file, configurable using |g:localvimrc_ask|.

v1870 : 2007-09-28

  - new configuration variable |g:localvimrc_name| to change filename.
  - new configuration variable |g:localvimrc_count| to limit number of loaded files.

v1613 : 2007-04-05

  - switched to arrays in vim 7.
  - escape file/path names correctly.

v1.2 : 2002-10-09

  - initial version


[Bitbucket]: https://bitbucket.org/embear/localvimrc
[GitHub]: https://github.com/embear/vim-localvimrc
[VIM online]: http://www.vim.org/scripts/script.php?script_id=441
