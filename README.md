# Localvimrc

This plugin searches for local vimrc files in the file system tree of the
currently opened file. It searches for all ".lvimrc" files from the directory
of the file up to the root directory. By default those files are loaded in
order from the root directory to the directory of the file. The filename and
amount of loaded files are customizable through global variables.

For security reasons it the plugin asks for confirmation before loading a local
vimrc file and loads it using |:sandbox| command. The plugin asks once per
session and local vimrc before loading it, if the file didn't change since
previous loading.

It is possible to define a whitelist and a blacklist of local vimrc files that
are loaded or ignored unconditionally.

The plugin can be found on [GitHub] and [VIM online].

## Installation

### Using a vimball archive

Download the archive at [VIM online] and run

```sh
vim -c 'so %|q' localvimrc.vmb
```

### Using Vim 8 package management

This is an elegant way to separate plugins from each other and be easily able
to completely remove a plugin later.

```sh
mkdir -p ~/.vim/pack/localvimrc/start/
git clone --depth 1 https://github.com/embear/vim-localvimrc.git ~/.vim/pack/localvimrc/start/localvimrc
vim -c 'packloadall|helptags ALL'
```

### Using a third party package manager

If the installed vim is older than version 8 it is possible to use a third
party package manager. For example install [vim-plug] and add the following to
your global vimrc:

```vim
call plug#begin()

Plug 'embear/vim-localvimrc'

call plug#end()
```

Then actually install the plugin:

```sh
vim -c 'PlugInstall'
```

Other options for a package manager are [vundle], [dein], [neobundle], [pathogen] or [packer].

## Commands

### The `LocalVimRC` command

Resource all local vimrc files for the current buffer.

### The `LocalVimRCClear` command

Clear all stored decisions made in the past, when the plugin asked about
sourcing a local vimrc file.

### The `LocalVimRCCleanup` command

Remove all stored decisions for local vimrc files that no longer exist.

### The `LocalVimRCForget` command

Remove stored decisions for given local vimrc files.

### The `LocalVimRCEdit` command

Open the local vimrc file for the current buffer in an split window for
editing. If more than one local vimrc file has been sourced, the user can
decide which file to edit.

### The `LocalVimRCEnable` command

Globally enable the loading of local vimrc files if loading has been disabled
by |LocalVimRCDisable| or by setting |g:localvimrc_enable| to `0` during
startup.

Enabling local vimrc using this command will trigger loading of local vimrc
files for the currently active buffer. It will *not* load the local vimrc files
for any other buffer. This will be done by an autocommand later when another
buffer gets active and the configured |g:localvimrc_event| autocommand gets
active. This is the case for the default |BufWinEnter|.

### The `LocalVimRCDisable` command

Globally disable the loading of local vimrc files if loading has been disabled
by |LocalVimRCEnable| or by setting |g:localvimrc_enable| to `1` during
startup.

### The `LocalVimRCDebugShow` command

Show all stored debugging messages. To see any message with this command
debugging needs to be enabled with |g:localvimrc_debug|. The number of messages
stored and printed can be limited using the setting |g:localvimrc_debug_lines|.

### The `LocalVimRCDebugDump` command

Write all stored debugging messages to given file. To write any message with
this command debugging needs to be enabled with |g:localvimrc_debug|. The
number of messages stored and written can be limited using the setting
|g:localvimrc_debug_lines|.

## Functions

### The `LocalVimRCFinish` function

After a call to this function the sourcing of any remaining local vimrc files
will be skipped. In combination with the |g:localvimrc_reverse| option it is
possible to end the processing of local vimrc files for example at the root of
the project by adding the following command to the local vimrc file in the root
of the project:

```vim
call LocalVimRCFinish()
```

## Variables

The plugin provides several convenience variables to make it easier to set up
path dependent setting like for example makeprg. These variables are only
available inside your local vimrc file because they are only unambiguous there.

Adding the following lines to a local vimrc in the root directory of a project
modify the behavior of |:make| to change into a build directory and call make
there:

```vim
let &l:makeprg="cd ".g:localvimrc_script_dir_unresolved."/build && make"
```

------------------------------------------------------------

**NOTE:**

This is only possible if you disable sandbox mode.

------------------------------------------------------------

Other variables provide a way to prevent multiple execution of commands. They
can be used to implement guards:

```vim
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

To change settings from their default add  similar line to your global |vimrc|
file.

```vim
let g:option_name=option_value
```

### The `g:localvimrc_enable` setting

Globally enable/disable loading of local vimrc files globally. The behavior can
be changed during runtime using the commands |LocalVimRCEnable| and
|LocalVimRCDisable|.

  - Value `0`: Disable loading of any local vimrc files.
  - Value `1`: Enable loading of local vimrc files.
  - Default: `1`

### The `g:localvimrc_name` setting

List of filenames of local vimrc files. The given name can include a directory
name such as ".config/localvimrc".

Previous versions of localvimrc only supported a single file as string. This is
still supported for backward compatibility.

By default the local vimrc files are expected to contain vim script. For Neovim
there is additional support for Lua. In order to use Lua code in the local
vimrc, the file name must have the extension `.lua`.

  - Default: `[ ".lvimrc" ]`

### The `g:localvimrc_event` setting

List of autocommand events that trigger local vimrc file loading.

  - Default: `[ "BufWinEnter" ]`

For more information see |autocmd-events|.

------------------------------------------------------------

**NOTE:**

BufWinEnter is the default to enable lines like

```vim
setlocal colorcolumn=+1
```

in the local vimrc file. Settings "local to window" need to be set for every
time a buffer is displayed in a window.

Because the plugin searches local vimrc files in the path of the currently
opened file not all autocommand events make sense. For example the event
|VimEnter| might cause problems. When that event is emitted it is possible that
no file is opened but some temporary buffer is currently shown. This will lead
to an unexpected behavior. If you would like to apply settings only once per
running Vim instance please use |g:localvimrc_sourced_once_for_file| and
|g:localvimrc_sourced_once|. An example how to use those variables in a local
vimrc file is described in the introduction to |localvimrc-variables|.

------------------------------------------------------------

### The `g:localvimrc_event_pattern` setting

String defining the pattern for which the autocommand events trigger local
vimrc file loading.

  - Default: `"*"`

For more information see |autocmd-patterns|.

### The `g:localvimrc_reverse` setting

Reverse behavior of loading local vimrc files.

  - Value `0`: Load files in order from root directory to directory of the file.
  - Value `1`: Load files in order from directory of the file to root directory.
  - Default: `0`

### The `g:localvimrc_count` setting

On the way from root, the last localvimrc_count files are sourced.

**NOTE:**

This might load files not located in the edited files directory or even not
located in the projects directory. If this is of concern use the
`g:localvimrc_file_directory_only` setting.

  - Default: `-1` (all)

### The `g:localvimrc_file_directory_only` setting

Just use local vimrc file located in the edited files directory.

**NOTE:**

This might end in not loading any local vimrc files at all. If limiting the
number of loaded local vimrc files is of concern use the `g:localvimrc_count`
setting.

  - Value `0`: Load all local vimrc files in the tree from root to file.
  - Value `1`: Load only file in the same directory as edited file.
  - Default: `0`

### The `g:localvimrc_sandbox` setting

Source the found local vimrc files in a sandbox for security reasons.

  - Value `0`: Don't load vimrc file in a sandbox.
  - Value `1`: Load vimrc file in a sandbox.
  - Default: `1`

### The `g:localvimrc_ask` setting

Ask before sourcing any local vimrc file. In a vim session the question is only
asked once as long as the local vimrc file has not been changed.

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

Files matching |g:localvimrc_whitelist| are sourced even if they are matched by
|g:localvimrc_blacklist|.

See |regular-expression| for patterns that are accepted.

Example:

```vim
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

```vim
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

### The `g:localvimrc_python2_enable` setting

Enable probing whether python 2 is available and usable for calculating local
vimrc file checksums, in case |sha256()| is not available.

- Default: `1`

### The `g:localvimrc_python3_enable` setting

Enable probing whether python 3 is available and usable for calculating local
vimrc file checksums, in case |sha256()| is not available.

- Default: `1`

### The `g:localvimrc_debug` setting

Debug level for this script. The messages can be shown with
|LocalVimRCDebugShow| or written to a file with |LocalVimRCDebugDump|.

  - Default: `0`

### The `g:localvimrc_debug_lines` setting

Limit for the number of debug messages stored. The messages can be shown with
|LocalVimRCDebugShow| or written to a file with |LocalVimRCDebugDump|.

  - Default: `100`

## Autocommands

If enabled localvimrc emits autocommands before and after sourcing a local
vimrc file. The autocommands are emitted as |User| events. Because of that
commands need to be registered in the following way:

```vim
autocmd User LocalVimRCPre  echom 'before loading local vimrc'
autocmd User LocalVimRCPost echom 'after loading local vimrc'
```

### The `LocalVimRCPre` autocommand

This autocommand is emitted right before sourcing each local vimrc file.

### The `LocalVimRCPost` autocommand

This autocommands is emitted right after sourcing each local vimrc file.

## Frequently Asked Questions

### modeline settings are overwritten by local vimrc

Depending on the |g:localvimrc_event| that is used to trigger loading local
vimrc files it is possible that |modeline| already had been parsed. This might
be cause problems. If for example there is `set ts=8 sts=4 sw=4 et` in the
local vimrc and a Makefile contains `# vim: ts=4 sts=0 sw=4 noet` this modeline
will not get applied with default settings of localvimrc. There are two
possibilities to solve this.

The first solution is to use |BufRead| as value for |g:localvimrc_event|. This
event is emitted by Vim before modelines are processed.

The second solution is to move all those settings to the local vimrc file and
use different settings depending on the |filetype|:

```vim
if &ft == "make"
  setl ts=4 sts=0 sw=4 noet
else
  setl ts=8 sts=4 sw=4 et
endif
```

### Project specific settings for other plugins are ignored

Most plugins require to have their configuration variables set when the plugin
is loaded. If you want to have project specific settings for those plugins you
run into a chicken and egg problem. This is because localvimrc is only able to
load the project specific configuration when a buffer in the project is loaded.
By that time the other plugins are already loaded and the project specific
configurations are most likely ignored. A solution to this is to make the
plugin you want to configure an optional plugin (see |:packadd|). This way it
is possible to do the settings in the local vimrc file and activate the plugin
afterwards. To do so add something like this to your local vimrc file:

```vim
" NOTE: <PLUGIN> needs to be replaced with the directory name of the plugin
if !g:localvimrc_sourced_once
  " add your <PLUGIN> settings here
  let g:plugin_setting = 1000

  " late loading of plugin
  packadd <PLUGIN>
endif
```

## Contribute

To contact the author (Markus Braun), please send an email to <markus.braun@krawel.de>

If you think this plugin could be improved, fork on [GitHub] and send a pull
request or just tell me your ideas.

If you encounter a bug please enable debugging, export debugging messages to
a file and create a bug report on [GitHub]. Debug messages can be enabled
temporary and exported to a file called `localvimrc_debug.txt` on command line
with the following command:

```sh
vim --cmd "let g:localvimrc_debug=99" -c "LocalVimRCDebugDump localvimrc_debug.txt" your_file
```

## Credits

- Simon Howard for his hint about "sandbox"
- Mark Weber for the idea of using checksums
- Daniel Hahler for various patches
- Justin M. Keyes for ideas to improve this plugin
- Lars Winderling for whitelist/blacklist patch
- Michon van Dooren for autocommands patch
- Benoit de Chezell for fix with nested execution
- Huy Le for patch to support Lua scripts in Neovim

## Changelog

v3.2.0 : 2024-10-25

  - add command |LocalVimRCDebugDump| to write debug messages to a file.
  - add support for Lua scripts when using Neovim.
  - for search path fallback to the current working directory, it checks for an existing directory of the current buffer rather than an empty directory name.
  - fix a bug with printing error messages
  
v3.1.0 : 2020-05-20

  - add option to disable probing of Python versions
  - prevent recursive sourcing of local vimrc files
  - better handling of syntax errors in sourced local vimrc files

v3.0.1 : 2018-08-21

  - fix a compatibility issue with unavailable |v:true| and |v:false| in Vim version 7.4

v3.0.0 : 2018-08-14

  - use SHA256 as for calculating checksums and use FNV-1 as fallback.
  - add command |LocalVimRCCleanup| to remove all unusable persistence data.
  - add command |LocalVimRCForget| to remove persistence data for given files.
  - add command |LocalVimRCDebugShow| to show debug messages.
  - add setting |g:localvimrc_debug_lines| to limit the number of stored debug messages.

v2.7.0 : 2018-03-19

  - add setting |g:localvimrc_enable| and commands |LocalVimRCEnable| and |LocalVimRCDisable| to globally disable processing of local vimrc files.
  - add setting |g:localvimrc_event_pattern| to change the pattern for which the autocommand is executed.

v2.6.1 : 2018-02-20

  - fix a bug with missing uniq() in Vim version 7.4

v2.6.0 : 2018-01-22

  - add command |LocalVimRCEdit| to edit sourced local vimrc files for the current buffer.

v2.5.0 : 2017-03-08

  - add unit tests.
  - settings |g:localvimrc_whitelist| and |g:localvimrc_blacklist| now takes optionally a list of regular expressions.
  - add convenience variables |g:localvimrc_script_unresolved| and |g:localvimrc_script_dir_unresolved|.
  - add ability to view local vimrc before sourcing when |g:localvimrc_ask| is enabled.
  - emit autocommands before and after sourcing files.
  - add |g:localvimrc_file_directory_only| to limit sourcing to local vimrc files in the same directory as the edited file.
  - add |LocalVimRCFinish| function to stop loading of remaining local vimrc files from within a local vimrc file.

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


[GitHub]: https://github.com/embear/vim-localvimrc
[VIM online]: https://www.vim.org/scripts/script.php?script_id=441
[dein]: https://github.com/Shougo/dein.vim
[neobundle]: https://github.com/Shougo/neobundle.vim
[packer]: https://github.com/wbthomason/packer.nvim
[pathogen]: https://github.com/tpope/vim-pathogen
[vim-plug]: https://github.com/junegunn/vim-plug
[vundle]: https://github.com/gmarik/vundle
