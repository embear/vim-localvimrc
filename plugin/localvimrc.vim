" Name:    localvimrc.vim
" Version: 2.2.0
" Author:  Markus Braun <markus.braun@krawel.de>
" Summary: Vim plugin to search local vimrc files and load them.
" Licence: This program is free software: you can redistribute it and/or modify
"          it under the terms of the GNU General Public License as published by
"          the Free Software Foundation, either version 3 of the License, or
"          (at your option) any later version.
"
"          This program is distributed in the hope that it will be useful,
"          but WITHOUT ANY WARRANTY; without even the implied warranty of
"          MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
"          GNU General Public License for more details.
"
"          You should have received a copy of the GNU General Public License
"          along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" Section: Plugin header {{{1

" guard against multiple loads {{{2
if (exists("g:loaded_localvimrc") || &cp)
  finish
endif
let g:loaded_localvimrc = 1

" check for correct vim version {{{2
if version < 702
  finish
endif

" define default "localvimrc_name" {{{2
" copy to script local variable to prevent .lvimrc modifying the name option.
if (!exists("g:localvimrc_name"))
  let s:localvimrc_name = ".lvimrc"
else
  let s:localvimrc_name = g:localvimrc_name
endif

" define default "localvimrc_reverse" {{{2
" copy to script local variable to prevent .lvimrc modifying the reverse
" option.
if (!exists("g:localvimrc_reverse"))
  let s:localvimrc_reverse = 0
else
  let s:localvimrc_reverse = g:localvimrc_reverse
endif

" define default "localvimrc_count" {{{2
" copy to script local variable to prevent .lvimrc modifying the count option.
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
" copy to script local variable to prevent .lvimrc modifying the ask option.
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

" initialize answer dictionary {{{2
let s:localvimrc_answers = {}

" initialize checksum dictionary {{{2
let s:localvimrc_checksums = {}

" define default "localvimrc_persistent" {{{2
" make decisions persistent over multiple vim runs
if (!exists("g:localvimrc_persistent"))
  let s:localvimrc_persistent = 0
else
  let s:localvimrc_persistent = g:localvimrc_persistent
endif

" define default "localvimrc_debug" {{{2
if (!exists("g:localvimrc_debug"))
  let g:localvimrc_debug = 0
endif

" Section: Autocmd setup {{{1

if has("autocmd")
  augroup localvimrc
    autocmd!

    " call s:LocalVimRC() when creating ore reading any file
    autocmd BufWinEnter * call s:LocalVimRC()
  augroup END
endif

" Section: Functions {{{1

" Function: s:LocalVimRC() {{{2
"
" search all local vimrc files from current directory up to root directory and
" source them in reverse order.
"
function! s:LocalVimRC()
  " begin marker
  call s:LocalVimRCDebug(1, "==================================================")

  " print version
  call s:LocalVimRCDebug(1, "localvimrc.vim " . g:loaded_localvimrc)

  " read persistent information
  call s:LocalVimRCReadPersistent()

  " only consider normal buffers (skip especially CommandT's GoToFile buffer)
  if (&buftype != "")
    call s:LocalVimRCDebug(1, "not a normal buffer, exiting")
    return
  endif

  " directory of current file (correctly escaped)
  let l:directory = fnameescape(expand("%:p:h"))
  if empty(l:directory)
    let l:directory = fnameescape(getcwd())
  endif
  call s:LocalVimRCDebug(2, "searching directory \"" . l:directory . "\"")

  " generate a list of all local vimrc files with absolute file names along path to root
  let l:absolute = {}
  for l:rcfile in findfile(s:localvimrc_name, l:directory . ";", -1)
    let l:absolute[resolve(fnamemodify(l:rcfile, ":p"))] = ""
  endfor
  let l:rcfiles = sort(keys(l:absolute))
  call s:LocalVimRCDebug(1, "found files: " . string(l:rcfiles))

  " shrink list of found files
  if (s:localvimrc_count >= 0 && s:localvimrc_count < len(l:rcfiles))
    call remove(l:rcfiles, 0, len(l:rcfiles) - s:localvimrc_count - 1)
  endif

  " reverse order of found files if reverse loading is requested
  if (s:localvimrc_reverse != 0)
    call reverse(l:rcfiles)
  endif

  call s:LocalVimRCDebug(1, "candidate files: " . string(l:rcfiles))

  " store name and directory of file
  let g:localvimrc_file = resolve(expand("<afile>"))
  let g:localvimrc_file_dir = fnamemodify(g:localvimrc_file, ":h")

  " source all found local vimrc files along path from root (reverse order)
  let l:answer = ""
  for l:rcfile in l:rcfiles
    call s:LocalVimRCDebug(2, "processing \"" . l:rcfile . "\"")
    let l:rcfile_load = "unknown"

    if filereadable(l:rcfile)
      " check if whitelisted
      if (l:rcfile_load == "unknown")
        if (match(l:rcfile, s:localvimrc_whitelist) != -1)
          call s:LocalVimRCDebug(2, l:rcfile . " is whitelisted")
          let l:rcfile_load = "yes"
        endif
      endif

      " check if blacklisted
      if (l:rcfile_load == "unknown")
        if (match(l:rcfile, s:localvimrc_blacklist) != -1)
          call s:LocalVimRCDebug(2, l:rcfile . " is blacklisted")
          let l:rcfile_load = "no"
        endif
      endif

      " check if an answer has been given for the same file
      if exists("s:localvimrc_answers[l:rcfile]")
        if (s:LocalVimRCCheckChecksum(l:rcfile) == 1)
          call s:LocalVimRCDebug(2, "reuse previous answer \"" . s:localvimrc_answers[l:rcfile] . "\"")

          " check the answer
          if (s:localvimrc_answers[l:rcfile] =~? '^y$')
            let l:rcfile_load = "yes"
          elseif (s:localvimrc_answers[l:rcfile] =~? '^n$')
            let l:rcfile_load = "no"
          endif
        else
          call s:LocalVimRCDebug(2, "checksum mismatch, no answer reuse")
        endif
      endif

      " ask if in interactive mode
      if (l:rcfile_load == "unknown")
        if (s:localvimrc_ask == 1)
          if (l:answer !~? "^a$")
            call s:LocalVimRCDebug(2, "need to ask")
            let l:answer = ""
            while (l:answer !~? '^[ynaq]$')
              if (s:localvimrc_persistent == 0)
                let l:message = "localvimrc: source " . l:rcfile . "? ([y]es/[n]o/[a]ll/[q]uit) "
              elseif (s:localvimrc_persistent == 1)
                let l:message = "localvimrc: source " . l:rcfile . "? ([y]es/[n]o/[a]ll/[q]uit ; persistent [Y]es/[N]o/[A]ll) "
              else
                let l:message = "localvimrc: source " . l:rcfile . "? ([y]es/[n]o/[a]ll/[q]uit) "
              endif
              let l:answer = input(l:message)
              call s:LocalVimRCDebug(2, "answer is \"" . l:answer . "\"")
            endwhile
          endif

          " make answer upper case if persistence is 2 ("force")
          if (s:localvimrc_persistent == 2)
            let l:answer = toupper(l:answer)
          endif

          " store y/n answers
          if (l:answer =~? "^y$")
            let s:localvimrc_answers[l:rcfile] = l:answer
          elseif (l:answer =~? "^n$")
            let s:localvimrc_answers[l:rcfile] = l:answer
          elseif (l:answer =~# "^a$")
            let s:localvimrc_answers[l:rcfile] = "y"
          elseif (l:answer =~# "^A$")
            let s:localvimrc_answers[l:rcfile] = "Y"
          endif

          " check the answer
          if (l:answer =~? '^[ya]$')
            let l:rcfile_load = "yes"
          elseif (l:answer =~? "^q$")
            call s:LocalVimRCDebug(1, "ended processing files")
            break
          endif
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
        " store name and directory of script
        let g:localvimrc_script = l:rcfile
        let g:localvimrc_script_dir = fnamemodify(g:localvimrc_script, ":h")

        let l:command = "silent "

        " add 'sandbox' if requested
        if (s:localvimrc_sandbox != 0)
          let l:command .= "sandbox "
          call s:LocalVimRCDebug(2, "using sandbox")
        endif
        let l:command .= "source " . fnameescape(l:rcfile)

        " execute the command
        exec l:command
        call s:LocalVimRCDebug(1, "sourced " . l:rcfile)

        " remove global variables again
        unlet g:localvimrc_script
        unlet g:localvimrc_script_dir
      else
        call s:LocalVimRCDebug(1, "skipping " . l:rcfile)
      endif

      " calculate checksum for each processed file
      call s:LocalVimRCCalcChecksum(l:rcfile)

    endif
  endfor

  " remove global variables again
  unlet g:localvimrc_file
  unlet g:localvimrc_file_dir

  " make information persistent
  call s:LocalVimRCWritePersistent()

  " end marker
  call s:LocalVimRCDebug(1, "==================================================")
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
  " overwrite answers with persistent data
  if exists("s:localvimrc_checksums[l:file]")
    call s:LocalVimRCDebug(3, "checksum check -> ".l:file . " : " . l:checksum . " : " . s:localvimrc_checksums[l:file])

    if (s:localvimrc_checksums[l:file] == l:checksum)
      let l:return = 1
    endif

  endif

  return l:return
endfunction

" Function: s:LocalVimRCReadPersistent() {{{2
"
" read decision variables from global variable
"
function! s:LocalVimRCReadPersistent()
  if (s:localvimrc_persistent >= 1)
    if stridx(&viminfo, "!") >= 0
      if exists("g:LOCALVIMRC_ANSWERS")
        " force g:LOCALVIMRC_ANSWERS to be a dictionary
        if (type(g:LOCALVIMRC_ANSWERS) != type({}))
          unlet g:LOCALVIMRC_ANSWERS
          let g:LOCALVIMRC_ANSWERS = {}
          call s:LocalVimRCDebug(3, "needed to reset g:LOCALVIMRC_ANSWERS")
        endif
	" Get missing answers from persistent data.
        for l:rcfile in keys(g:LOCALVIMRC_ANSWERS)
	  if ! exists('s:localvimrc_ansers[l:rcfile]')
	    let s:localvimrc_answers[l:rcfile] = g:LOCALVIMRC_ANSWERS[l:rcfile]
	  endif
        endfor
        call s:LocalVimRCDebug(3, "read answer persistent data: " . string(s:localvimrc_answers))
      endif
      if exists("g:LOCALVIMRC_CHECKSUMS")
        " force g:LOCALVIMRC_CHECKSUMS to be a dictionary
        if (type(g:LOCALVIMRC_CHECKSUMS) != type({}))
          unlet g:LOCALVIMRC_CHECKSUMS
          let g:LOCALVIMRC_CHECKSUMS = {}
          call s:LocalVimRCDebug(3, "needed to reset g:LOCALVIMRC_CHECKSUMS")
        endif
	" Get missing checksums from persistent data.
        for l:rcfile in keys(g:LOCALVIMRC_CHECKSUMS)
	  if ! exists('s:localvimrc_checksums[l:rcfile]')
	    let s:localvimrc_checksums[l:rcfile] = g:LOCALVIMRC_CHECKSUMS[l:rcfile]
	  endif
        endfor
        call s:LocalVimRCDebug(3, "read checksum persistent data: " . string(s:localvimrc_checksums))
      endif
    endif
  endif
endfunction

" Function: s:LocalVimRCWritePersistent() {{{2
"
" write decision variables to global variable to make them persistent
"
function! s:LocalVimRCWritePersistent()
  if (s:localvimrc_persistent >= 1)
    " select only data relevant for persistence
    let l:persistent_answers = filter(copy(s:localvimrc_answers), 'v:val =~# "^[YN]$"')
    let l:persistent_checksums = {}
    for l:rcfile in keys(l:persistent_answers)
      " NOTE: might happen after "q"
      try
        let l:persistent_checksums[l:rcfile] = s:localvimrc_checksums[l:rcfile]
		  catch /^Vim\%((\a\+)\)\=:E715/	" catch error E716: Key not present in Dictionary
      endtry

    endfor

    " if there are answers to store and global variables are enabled for viminfo
    if (len(l:persistent_answers) > 0)
      if (stridx(&viminfo, "!") >= 0)
        let g:LOCALVIMRC_ANSWERS = l:persistent_answers
        call s:LocalVimRCDebug(3, "write answer persistent data: " . string(g:LOCALVIMRC_ANSWERS))
        let g:LOCALVIMRC_CHECKSUMS = l:persistent_checksums
        call s:LocalVimRCDebug(3, "write checksum persistent data: " . string(g:LOCALVIMRC_CHECKSUMS))
      else
        call s:LocalVimRCDebug(3, "viminfo setting has no '!' flag, no persistence available")
        call s:LocalVimRCError("viminfo setting has no '!' flag, no persistence available")
      endif
    endif
  else
    if exists("g:LOCALVIMRC_ANSWERS")
      unlet g:LOCALVIMRC_ANSWERS
      call s:LocalVimRCDebug(3, "deleted answer persistent data")
    endif
    if exists("g:LOCALVIMRC_CHECKSUMS")
      unlet g:LOCALVIMRC_CHECKSUMS
      call s:LocalVimRCDebug(3, "deleted checksum persistent data")
    endif

  endif
endfunction

" Function: s:LocalVimRCClear() {{{2
"
" clear all stored data
"
function! s:LocalVimRCClear()
  if exists("s:localvimrc_answers")
    unlet s:localvimrc_answers
    call s:LocalVimRCDebug(3, "deleted answer local data")
  endif
  if exists("s:localvimrc_checksums")
    unlet s:localvimrc_checksums
    call s:LocalVimRCDebug(3, "deleted checksum local data")
  endif
  if exists("g:LOCALVIMRC_ANSWERS")
    unlet g:LOCALVIMRC_ANSWERS
    call s:LocalVimRCDebug(3, "deleted answer persistent data")
  endif
  if exists("g:LOCALVIMRC_CHECKSUMS")
    unlet g:LOCALVIMRC_CHECKSUMS
    call s:LocalVimRCDebug(3, "deleted checksum persistent data")
  endif
endfunction

" Function: s:LocalVimRCError(text) {{{2
"
" output error message
"
function! s:LocalVimRCError(text)
  echohl ErrorMsg | echo "localvimrc: " . a:text | echohl None
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

" Section: Commands {{{1
command! LocalVimRCClear call s:LocalVimRCClear()

" vim600: foldmethod=marker foldlevel=0 :
