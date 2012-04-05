" Name:    localvimrc.vim
" Version: 2.0.0
" Author:  Markus Braun <markus.braun@krawel.de>
" Summary: Vim plugin to search local vimrc files and load them.
" Licence: This program is free software; you can redistribute it and/or
"          modify it under the terms of the GNU General Public License.
"          See http://www.gnu.org/copyleft/gpl.txt
"
" Section: Plugin header {{{1

" guard against multiple loads {{{2
if (exists("g:loaded_localvimrc") || &cp)
  finish
endif
let g:loaded_localvimrc = 2

" check for correct vim version {{{2
if version < 700
  finish
endif

" define default "localvimrc_name" {{{2
if (!exists("g:localvimrc_name"))
  let s:localvimrc_name = ".lvimrc"
else
  let s:localvimrc_name = g:localvimrc_name
endif

" define default "localvimrc_count" {{{2
if (!exists("g:localvimrc_count"))
  let s:localvimrc_count = -1
else
  let s:localvimrc_count = g:localvimrc_count
endif

" define default "localvimrc_sandbox" {{{2
" copy to script local variable to prevent .lvimrc disabling the sandbox
" again.
if (!exists("g:localvimrc_sandbox"))
  let s:localvimrc_sandbox = 1
else
  let s:localvimrc_sandbox = g:localvimrc_sandbox
endif

" define default "localvimrc_ask" {{{2
" copy to script local variable to prevent .lvimrc disabling the sandbox
" again.
if (!exists("g:localvimrc_ask"))
  let s:localvimrc_ask = 1
else
  let s:localvimrc_ask = g:localvimrc_ask
endif

" define default "localvimrc_whitelist" {{{2
" copy to script local variable to prevent .lvimrc modifying the whitelist.
if (!exists("g:localvimrc_whitelist"))
  let s:localvimrc_whitelist = "^$" " This never matches a file
else
  let s:localvimrc_whitelist = g:localvimrc_whitelist
endif

" define default "localvimrc_blacklist" {{{2
" copy to script local variable to prevent .lvimrc modifying the blacklist.
if (!exists("g:localvimrc_blacklist"))
  let s:localvimrc_blacklist = "^$" " This never matches a file
else
  let s:localvimrc_blacklist = g:localvimrc_blacklist
endif

" initialize checksum dictionary
let s:localvimrc_checksums = {}

" define default "localvimrc_debug" {{{2
if (!exists("g:localvimrc_debug"))
  let g:localvimrc_debug = 0
endif

" Section: Autocmd setup {{{1

if has("autocmd")
  augroup localvimrc
    autocmd!

    " call s:LocalVimRC() when creating ore reading any file
    autocmd VimEnter,BufNewFile,BufRead * call s:LocalVimRC()
  augroup END
endif

" Section: Functions {{{1

" Function: s:LocalVimRC() {{{2
"
" search all local vimrc files from current directory up to root directory and
" source them in reverse order.
"
function! s:LocalVimRC()
  " print version
  call s:LocalVimRCDebug(1, "localvimrc.vim " . g:loaded_localvimrc)

  " directory of current file (correctly escaped)
  let l:directory = fnameescape(expand("%:p:h"))
  if empty(l:directory)
    let l:directory = fnameescape(getcwd())
  endif
  call s:LocalVimRCDebug(2, "searching directory \"" . l:directory . "\"")

  " generate a list of all local vimrc files along path to root
  let l:rcfiles = findfile(s:localvimrc_name, l:directory . ";", -1)
  call s:LocalVimRCDebug(1, "found files: " . string(l:rcfiles))

  " shrink list of found files
  if s:localvimrc_count == -1
    let l:rcfiles = l:rcfiles[0:-1]
  elseif s:localvimrc_count == 0
    let l:rcfiles = []
  else
    let l:rcfiles = l:rcfiles[0:(s:localvimrc_count-1)]
  endif
  call s:LocalVimRCDebug(1, "candidate files: " . string(l:rcfiles))

  " source all found local vimrc files along path from root (reverse order)
  let l:answer = ""
  for l:rcfile in reverse(l:rcfiles)
    call s:LocalVimRCDebug(2, "processing \"" . l:rcfile . "\"")
    let l:rcfile_load = "unknown"

    if filereadable(l:rcfile)
      " check if whitelisted
      if (l:rcfile_load == "unknown")
        if (match(fnamemodify(l:rcfile, ":p"), s:localvimrc_whitelist) != -1)
          call s:LocalVimRCDebug(2, l:rcfile . " is whitelisted")
          let l:rcfile_load = "yes"
        endif
      endif

      " check if blacklisted
      if (l:rcfile_load == "unknown")
        if (match(fnamemodify(l:rcfile, ":p"), s:localvimrc_blacklist) != -1)
          call s:LocalVimRCDebug(2, l:rcfile . " is blacklisted")
          let l:rcfile_load = "no"
        endif
      endif
      
      " check if file had been loaded already
      if (s:LocalVimRCCheckChecksum(l:rcfile) == 1)
        call s:LocalVimRCDebug(2, l:rcfile . " was loaded at least once")
        let l:rcfile_load = "yes"
      endif

      " ask if in interactive mode
      if (l:rcfile_load == "unknown")
        if (s:localvimrc_ask == 1)
          if (l:answer != "a")
            let l:message = "localvimrc: source " . l:rcfile . "? (y/n/a/q) "
            let l:answer = input(l:message)
            call s:LocalVimRCDebug(2, "answer is \"" . l:answer . "\"")
          endif
        endif

        " check the answer
        if (l:answer == "y" || l:answer == "a")
          let l:rcfile_load = "yes"
        elseif (l:answer == "q")
          call s:LocalVimRCDebug(1, "ended processing files")
          break
        endif
      endif

      " load unconditionally if in non-interactive mode
      if (l:rcfile_load == "unknown")
        if (s:localvimrc_ask == 0)
          let l:rcfile_load = "yes"
        endif
      endif

      " should this rc file be loaded?
      if (l:rcfile_load == "yes")
        " calculate checksum
        if (s:LocalVimRCCheckChecksum(l:rcfile) == 0)
          call s:LocalVimRCCalcChecksum(l:rcfile)
        endif

        let l:command = ""

        " add 'sandbox' if requested
        if (s:localvimrc_sandbox != 0)
          let l:command .= "sandbox "
          call s:LocalVimRCDebug(2, "using sandbox")
        endif
        let l:command .= "source " . fnameescape(l:rcfile)

        " execute the command
        exec l:command
        call s:LocalVimRCDebug(1, "sourced " . l:rcfile)

      else
        call s:LocalVimRCDebug(1, "skipping " . l:rcfile)
      endif

    endif
  endfor

  " clear command line
  redraw!
endfunction

" Function: s:LocalVimRCCalcChecksum(filename) {{{2
"
" calculate checksum and store it in dictionary
"
function! s:LocalVimRCCalcChecksum(filename)
  let l:file = fnameescape(a:filename)
  let l:checksum = getfsize(l:file) . getfperm(l:file) . getftime(l:file)
  let s:localvimrc_checksums[l:file] = l:checksum

  call s:LocalVimRCDebug(3, "checksum calc -> ".l:file . " : " . l:checksum)
endfunction

" Function: s:LocalVimRCCheckChecksum(filename) {{{2
"
" Check checksum in dictionary. Return "0" if it does not exist, "1" otherwise
"
function! s:LocalVimRCCheckChecksum(filename)
  let l:return = 0
  let l:file = fnameescape(a:filename)
  let l:checksum = getfsize(l:file) . getfperm(l:file) . getftime(l:file)

  if exists("s:localvimrc_checksums[l:file]")
    call s:LocalVimRCDebug(3, "checksum check -> ".l:file . " : " . l:checksum . " : " . s:localvimrc_checksums[l:file])

    if s:localvimrc_checksums[l:file] == l:checksum
      let l:return = 1
    endif

  endif

  return l:return
endfunction

" Function: s:LocalVimRCDebug(level, text) {{{2
"
" output debug message, if this message has high enough importance
"
function! s:LocalVimRCDebug(level, text)
  if (g:localvimrc_debug >= a:level)
    echom "localvimrc: " . a:text
  endif
endfunction

" vim600: foldmethod=marker foldlevel=0 :
