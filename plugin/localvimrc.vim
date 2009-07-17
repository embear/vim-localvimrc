" Name:    localvimrc.vim
" Version: $Id$
" Author:  Markus Braun
" Summary: Search local vimrc files and load them.
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt
" Section: Documentation {{{1
" Description:
"
"   This plugin searches for local vimrc files in the file system tree of the
"   currently opened file. By default it searches for all ".lvimrc" files from
"   the file's directory up to the root directory and loads them in reverse
"   order. The filename and amount of loaded files is customizable through
"   global variables.
"
" Installation:
"
"   Copy the localvimrc.vim file to the $HOME/.vim/plugin directory.
"   Refer to ':help add-plugin', ':help add-global-plugin' and ':help
"   runtimepath' for more details about Vim plugins.
"
" Variables:
"
"   g:localvimrc_name
"     Filename of local vimrc files.
"     Defaults to ".lvimrc".
"
"   g:localvimrc_count
"     On the way from root, the last localvimrc_count files are sourced.
"     Defaults to -1 (all)
"
"   g:localvimrc_sandbox
"     Source the found local vimrc files in a sandbox for security reasons.
"     Defaults to 1.
"
"   g:localvimrc_ask
"     Ask before sourcing any local vimrc file.
"     Defaults to 1.
"
" Credits:
" - Simon Howard for his hint about "sandbox"
"
" Section: Plugin header {{{1
" guard against multiple loads {{{2
if (exists("g:loaded_localvimrc") || &cp)
  finish
endif
let g:loaded_localvimrc = "$Revision$"

" check for correct vim version {{{2
if version < 700
  finish
endif

" define default local vimrc file name {{{2
if (!exists("g:localvimrc_name"))
  let g:localvimrc_name = ".lvimrc"
endif

" define default "search depth" {{{2
if (!exists("g:localvimrc_count"))
  let g:localvimrc_count = -1
endif

" define default for sandbox {{{2
if (!exists("g:localvimrc_sandbox"))
  let g:localvimrc_sandbox = 1
endif

" define default for asking {{{2
if (!exists("g:localvimrc_ask"))
  let g:localvimrc_ask = 1
endif

" define default for debugging {{{2
if (!exists("g:localvimrc_debug"))
  let g:localvimrc_debug = 0
endif

" Section: Functions {{{1
" Function: s:localvimrc {{{2
"
" search all local vimrc files from current directory up to root directory and
" source them in reverse order.
function! s:localvimrc()
  " print version
  call s:localvimrcDebug(1, "localvimrc.vim " . g:loaded_localvimrc)

  " directory of current file (correctly escaped)
  let l:directory = escape(expand("%:p:h"), ' ~|!"$%&()=?{[]}+*#'."'")
  if empty(l:directory)
    let l:directory = escape(getcwd(), ' ~|!"$%&()=?{[]}+*#'."'")
  endif
  call s:localvimrcDebug(2, "searching directory \"" . l:directory . "\"")

  " generate a list of all local vimrc files along path to root
  let l:rcfiles = findfile(g:localvimrc_name, l:directory . ";", -1)
  call s:localvimrcDebug(1, "found files: " . string(l:rcfiles))

  " shrink list of found files
  if g:localvimrc_count == -1
    let l:rcfiles = l:rcfiles[0:-1]
  elseif g:localvimrc_count == 0
    let l:rcfiles = []
  else
    let l:rcfiles = l:rcfiles[0:(g:localvimrc_count-1)]
  endif
  call s:localvimrcDebug(1, "candidate files: " . string(l:rcfiles))

  " source all found local vimrc files along path from root (reverse order)
  let l:answer = ""
  for l:rcfile in reverse(l:rcfiles)
    call s:localvimrcDebug(2, "processing \"" . l:rcfile . "\"")

    if filereadable(l:rcfile)
      " ask if this rcfile should be loaded
      if (l:answer != "a")
        if (g:localvimrc_ask == 1)
          let l:message = "localvimrc: source " . l:rcfile . "? (y/n/a/q) "
          let l:answer = input(l:message)
          call s:localvimrcDebug(2, "answer is \"" . l:answer . "\"")
        else
          let l:answer = "a"
        endif
      endif

      " check the answer
      if (l:answer == "y" || l:answer == "a")

        " add 'sandbox' if requested
        if (g:localvimrc_sandbox != 0)
          let l:command = "sandbox "
          call s:localvimrcDebug(2, "using sandbox")
        else
          let l:command = ""
        endif
        let l:command .= "source " . escape(l:rcfile, ' ~|!"$%&()=?{[]}+*#'."'")

        " execute the command
        exec l:command
        call s:localvimrcDebug(1, "sourced " . l:rcfile)

      else
        call s:localvimrcDebug(1, "skipping " . l:rcfile)
        if (l:answer == "q")
          call s:localvimrcDebug(1, "end processing files")
          break
        endif
      endif

    endif
  endfor

  " clear command line
  redraw!
endfunction

" Function: s:localvimrcDebug(level, text) {{{2
"
" output debug message, if this message has high enough importance
function! s:localvimrcDebug(level, text)
  if (g:localvimrc_debug >= a:level)
    echom "localvimrc: " . a:text
  endif
endfunction

" Section: Autocmd setup {{{1
if has("autocmd")
  augroup localvimrc
    autocmd!
    " call s:localvimrc() when creating ore reading any file
    autocmd VimEnter,BufNewFile,BufRead * call s:localvimrc()
  augroup END
endif

" vim600: foldmethod=marker
