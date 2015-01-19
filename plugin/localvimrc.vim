" Name:    localvimrc.vim
" Version: 2.3.0
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
  let s:localvimrc_name = [ ".lvimrc" ]
else
  if type(g:localvimrc_name) == type("")
    let s:localvimrc_name = [ g:localvimrc_name ]
  elseif type(g:localvimrc_name) == type([])
    let s:localvimrc_name = g:localvimrc_name
  endif
endif

" define default "localvimrc_event" {{{2
" copy to script local variable to prevent .lvimrc modifying the name option.
if (!exists("g:localvimrc_event") || !(type(g:localvimrc_event) == type([])))
  let s:localvimrc_event = [ "BufWinEnter" ]
else
  let s:localvimrc_event = g:localvimrc_event
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

" define default "localvimrc_persistent" {{{2
" make decisions persistent over multiple vim runs
if (!exists("g:localvimrc_persistent"))
  let s:localvimrc_persistent = 0
else
  let s:localvimrc_persistent = g:localvimrc_persistent
endif

" define default "localvimrc_persistence_file" {{{2
" file where to store persistence information
if (!exists("g:localvimrc_persistence_file"))
  if has("win16") || has("win32") || has("win64") || has("win95")
    let s:localvimrc_persistence_file = expand('$HOME') . "/_localvimrc_persistent"
  else
    let s:localvimrc_persistence_file = expand('$HOME') . "/.localvimrc_persistent"
  endif
else
  let s:localvimrc_persistence_file = g:localvimrc_persistence_file
endif

" define default "localvimrc_debug" {{{2
if (!exists("g:localvimrc_debug"))
  let g:localvimrc_debug = 0
endif

" initialize data dictionary {{{2
" key: localvimrc file
" value: [ answer, sandbox_answer, checksum ]
let s:localvimrc_data = {}

" initialize sourced dictionary {{{2
" key: localvimrc file
" value: [ list of files triggered sourcing ]
let s:localvimrc_sourced = {}

" initialize persistence file checksum {{{2
let s:localvimrc_persistence_file_checksum = ""

" initialize persistent data {{{2
let s:localvimrc_persistent_data = {}

" Section: Autocmd setup {{{1

if has("autocmd")
  augroup localvimrc
    autocmd!

    for event in s:localvimrc_event
      " call s:LocalVimRC() when creating ore reading any file
      exec "autocmd ".event." * call s:LocalVimRC()"
    endfor
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
  " NOTE: in general the buftype is not set for new buffers (BufWinEnter),
  "       e.g. for help files via plugins (pydoc)
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
  for l:rcname in s:localvimrc_name
    for l:rcfile in findfile(l:rcname, l:directory . ";", -1)
      let l:absolute[resolve(fnamemodify(l:rcfile, ":p"))] = ""
    endfor
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

  " source all found local vimrc files along path from root (reverse order)
  let l:answer = ""
  let l:sandbox_answer = ""
  for l:rcfile in l:rcfiles
    call s:LocalVimRCDebug(2, "processing \"" . l:rcfile . "\"")
    let l:rcfile_load = "unknown"

    if filereadable(l:rcfile)
      " extract information
      if has_key(s:localvimrc_data, l:rcfile)
        if len(s:localvimrc_data[l:rcfile]) == 2
          let [ l:stored_answer, l:stored_checksum ] = s:localvimrc_data[l:rcfile]
          let l:stored_sandbox_answer = ""
        elseif len(s:localvimrc_data[l:rcfile]) == 3
          let [ l:stored_answer, l:stored_sandbox_answer, l:stored_checksum ] = s:localvimrc_data[l:rcfile]
        else
          let l:stored_answer = ""
          let l:stored_sandbox_answer = ""
          let l:stored_checksum = ""
        endif
      else
        let l:stored_answer = ""
        let l:stored_sandbox_answer = ""
        let l:stored_checksum = ""
      endif
      call s:LocalVimRCDebug(3, "stored information: answer = '" . l:stored_answer . "' sandbox answer = '" . l:stored_sandbox_answer . "' checksum = '" . l:stored_checksum . "'")

      " check if checksum is the same
      let l:checksum_is_same = s:LocalVimRCCheckChecksum(l:rcfile, l:stored_checksum)

      " reset answers if checksum changed
      if (!l:checksum_is_same)
        call s:LocalVimRCDebug(2, "checksum mismatch, no answer reuse")
        let l:stored_answer = ""
        let l:stored_sandbox_answer = ""
      else
        call s:LocalVimRCDebug(2, "reuse previous answer = '" . l:stored_answer . "' sandbox answer = '" . l:stored_sandbox_answer . "'")
      endif

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
      if !empty(l:stored_answer)
        " check the answer
        if (l:stored_answer =~? '^y$')
          let l:rcfile_load = "yes"
        elseif (l:stored_answer =~? '^n$')
          let l:rcfile_load = "no"
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

              " turn off possible previous :silent command to force this
              " message to be printed
              unsilent let l:answer = inputdialog(l:message)
              call s:LocalVimRCDebug(2, "answer is \"" . l:answer . "\"")

              if empty(l:answer)
                call s:LocalVimRCDebug(2, "aborting on empty answer")
                let l:answer = "q"
              endif
            endwhile
          endif

          " make answer upper case if persistence is 2 ("force")
          if (s:localvimrc_persistent == 2)
            let l:answer = toupper(l:answer)
          endif

          " store y/n answers
          if (l:answer =~? "^y$")
            let l:stored_answer = l:answer
          elseif (l:answer =~? "^n$")
            let l:stored_answer = l:answer
          elseif (l:answer =~# "^a$")
            let l:stored_answer = "y"
          elseif (l:answer =~# "^A$")
            let l:stored_answer = "Y"
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
        " store name and directory of file
        let g:localvimrc_file = resolve(expand("<afile>:p"))
        let g:localvimrc_file_dir = fnamemodify(g:localvimrc_file, ":h")
        call s:LocalVimRCDebug(3, "g:localvimrc_file = " . g:localvimrc_file . ", g:localvimrc_file_dir = " . g:localvimrc_file_dir)

        " store name and directory of script
        let g:localvimrc_script = l:rcfile
        let g:localvimrc_script_dir = fnamemodify(g:localvimrc_script, ":h")
        call s:LocalVimRCDebug(3, "g:localvimrc_script = " . g:localvimrc_script . ", g:localvimrc_script_dir = " . g:localvimrc_script_dir)

        " reset if checksum changed
        if (!l:checksum_is_same)
          if has_key(s:localvimrc_sourced, l:rcfile)
            unlet s:localvimrc_sourced[l:rcfile]
            call s:LocalVimRCDebug(2, "resetting 'sourced' information")
          endif
        endif

        " detect if this local vimrc file had been loaded
        let g:localvimrc_sourced_once = 0
        let g:localvimrc_sourced_once_for_file = 0
        if has_key(s:localvimrc_sourced, l:rcfile)
          let g:localvimrc_sourced_once = 1
          if index(s:localvimrc_sourced[l:rcfile], g:localvimrc_file) >= 0
            let g:localvimrc_sourced_once_for_file = 1
          else
            call add(s:localvimrc_sourced[l:rcfile], g:localvimrc_file)
          endif
        else
          let s:localvimrc_sourced[l:rcfile] = [ g:localvimrc_file ]
        endif
        call s:LocalVimRCDebug(3, "g:localvimrc_sourced_once = " . g:localvimrc_sourced_once . ", g:localvimrc_sourced_once_for_file = " . g:localvimrc_sourced_once_for_file)

        " generate command
        let l:command = "silent source " . fnameescape(l:rcfile)

        " add 'sandbox' if requested
        if (s:localvimrc_sandbox != 0)
          call s:LocalVimRCDebug(2, "using sandbox")
          try
            " execute the command
            exec "sandbox " . l:command
            call s:LocalVimRCDebug(1, "sourced " . l:rcfile)
          catch ^Vim\%((\a\+)\)\=:E48
            call s:LocalVimRCDebug(1, "unable to use sandbox on '" . l:rcfile . "'")

            if (s:localvimrc_ask == 1)
              if (l:sandbox_answer !~? "^a$")
                if l:stored_sandbox_answer != ""
                  let l:sandbox_answer = l:stored_sandbox_answer
                  call s:LocalVimRCDebug(2, "reuse previous sandbox answer \"" . l:stored_sandbox_answer . "\"")
                else
                  call s:LocalVimRCDebug(2, "need to ask")
                  let l:sandbox_answer = ""
                  while (l:sandbox_answer !~? '^[ynaq]$')
                    if (s:localvimrc_persistent == 0)
                      let l:message = "localvimrc: unable to use 'sandbox' for " . l:rcfile . ".\nlocalvimrc: Source it anyway? ([y]es/[n]o/[a]ll/[q]uit) "
                    elseif (s:localvimrc_persistent == 1)
                      let l:message = "localvimrc: unable to use 'sandbox' for " . l:rcfile . ".\nlocalvimrc: Source it anyway? ([y]es/[n]o/[a]ll/[q]uit ; persistent [Y]es/[N]o/[A]ll) "
                    else
                      let l:message = "localvimrc: unable to use 'sandbox' for " . l:rcfile . ".\nlocalvimrc: Source it anyway? ([y]es/[n]o/[a]ll/[q]uit) "
                    endif

                    " turn off possible previous :silent command to force this
                    " message to be printed
                    unsilent let l:sandbox_answer = inputdialog(l:message)
                    call s:LocalVimRCDebug(2, "sandbox answer is \"" . l:sandbox_answer . "\"")

                    if empty(l:sandbox_answer)
                      call s:LocalVimRCDebug(2, "aborting on empty sandbox answer")
                      let l:sandbox_answer = "q"
                    endif
                  endwhile
                endif
              endif

              " make sandbox_answer upper case if persistence is 2 ("force")
              if (s:localvimrc_persistent == 2)
                let l:sandbox_answer = toupper(l:sandbox_answer)
              endif

              " store y/n answers
              if (l:sandbox_answer =~? "^y$")
                let l:stored_sandbox_answer = l:sandbox_answer
              elseif (l:sandbox_answer =~? "^n$")
                let l:stored_sandbox_answer = l:sandbox_answer
              elseif (l:sandbox_answer =~# "^a$")
                let l:stored_sandbox_answer = "y"
              elseif (l:sandbox_answer =~# "^A$")
                let l:stored_sandbox_answer = "Y"
              endif

              " check the sandbox_answer
              if (l:sandbox_answer =~? '^[ya]$')
                " execute the command
                exec l:command
                call s:LocalVimRCDebug(1, "sourced " . l:rcfile)
              elseif (l:sandbox_answer =~? "^q$")
                call s:LocalVimRCDebug(1, "ended processing files")
                break
              endif
            endif
          endtry
        else
          " execute the command
          exec l:command
          call s:LocalVimRCDebug(1, "sourced " . l:rcfile)
        endif

        " remove global variables again
        unlet g:localvimrc_file
        unlet g:localvimrc_file_dir
        unlet g:localvimrc_script
        unlet g:localvimrc_script_dir
        unlet g:localvimrc_sourced_once
        unlet g:localvimrc_sourced_once_for_file
      else
        call s:LocalVimRCDebug(1, "skipping " . l:rcfile)
      endif

      " calculate checksum for each processed file
      let l:stored_checksum = s:LocalVimRCCalcChecksum(l:rcfile)

      " store information again
      let s:localvimrc_data[l:rcfile] = [ l:stored_answer, l:stored_sandbox_answer, l:stored_checksum ]
    endif
  endfor

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

  call s:LocalVimRCDebug(3, "checksum calc -> " . l:file . " : " . l:checksum)

  return l:checksum
endfunction

" Function: s:LocalVimRCCheckChecksum(filename, checksum) {{{2
"
" Check checksum in dictionary. Return "0" if it does not exist, "1" otherwise
"
function! s:LocalVimRCCheckChecksum(filename, checksum)
  let l:return = 0
  let l:file = fnameescape(a:filename)
  let l:checksum = s:LocalVimRCCalcChecksum(l:file)

  if (a:checksum == l:checksum)
    let l:return = 1
  endif

  return l:return
endfunction

" Function: s:LocalVimRCReadPersistent() {{{2
"
" read decision variables from persistence file
"
function! s:LocalVimRCReadPersistent()
  if (s:localvimrc_persistent >= 1)
    " check if persistence file is readable
    if filereadable(s:localvimrc_persistence_file)

      " check if reading is needed
      let l:checksum = s:LocalVimRCCalcChecksum(s:localvimrc_persistence_file)
      if l:checksum != s:localvimrc_persistence_file_checksum

        " read persistence file
        let l:serialized = readfile(s:localvimrc_persistence_file)
        call s:LocalVimRCDebug(3, "read persistent data: " . string(l:serialized))

        " deserialize stored persistence information
        for l:line in l:serialized
          let l:columns = split(l:line, '[^\\]\zs|\|^|', 1)
          if len(l:columns) != 3 && len(l:columns) != 4
            call s:LocalVimRCDebug(1, "error in persistence file")
            call s:LocalVimRCError("error in persistence file")
          else
            if len(l:columns) == 3
              let [ l:key, l:answer, l:checksum ] = l:columns
              let l:sandbox = ""
            elseif len(l:columns) == 4
              let [ l:key, l:answer, l:sandbox, l:checksum ] = l:columns
            endif
            let l:key = substitute(l:key, '\\|', '|', "g")
            let l:answer = substitute(l:answer, '\\|', '|', "g")
            let l:sandbox = substitute(l:sandbox, '\\|', '|', "g")
            let l:checksum = substitute(l:checksum, '\\|', '|', "g")
            let s:localvimrc_data[l:key] = [ l:answer, l:sandbox, l:checksum ]
          endif
        endfor
      else
        call s:LocalVimRCDebug(3, "persistence file did not change")
      endif
    else
      call s:LocalVimRCDebug(1, "unable to read persistence file '" . s:localvimrc_persistence_file . "'")
    endif
  endif
endfunction

" Function: s:LocalVimRCWritePersistent() {{{2
"
" write decision variables to persistence file
"
function! s:LocalVimRCWritePersistent()
  if (s:localvimrc_persistent >= 1)
    " select only data relevant for persistence
    let l:persistent_data = filter(copy(s:localvimrc_data), 'v:val[0] =~# "^[YN]$" || v:val[1] =~# "^[YN]$"')

    " if there are answers to store and global variables are enabled for viminfo
    if (len(l:persistent_data) > 0)
      if l:persistent_data != s:localvimrc_persistent_data
        " check if persistence file is writable
        if filereadable(s:localvimrc_persistence_file) && filewritable(s:localvimrc_persistence_file) ||
              \ !filereadable(s:localvimrc_persistence_file) && filewritable(fnamemodify(s:localvimrc_persistence_file, ":h"))
          let l:serialized = [ ]
          for [ l:key, l:value ] in items(l:persistent_data)
            if len(l:value) == 2
              let [ l:answer, l:checksum ] = l:value
              let l:sandbox = ""
            elseif len(l:value) == 3
              let [ l:answer, l:sandbox, l:checksum ] = l:value
            else
              let l:answer = ""
              let l:sandbox = ""
              let l:checksum = ""
            endif

            " delete none persisten answers
            if l:answer !~# "^[YN]$"
              let l:answer = ""
            endif
            if l:sandbox !~# "^[YN]$"
              let l:sandbox = ""
            endif

            call add(l:serialized, escape(l:key, '|') . "|" . escape(l:answer, '|') . "|" . escape(l:sandbox, '|') . "|" . escape(l:checksum, '|'))
          endfor

          call s:LocalVimRCDebug(3, "write persistent data: " . string(l:serialized))

          " first write backup file to avoid lost persistence information
          " on write errors if partition is full. Done this way because
          " write/rename approach causes permission problems with sudo.
          let l:backup_name = s:localvimrc_persistence_file . "~"
          let l:backup_content = readfile(s:localvimrc_persistence_file, "b")
          if (writefile(l:backup_content, l:backup_name, "b") == 0)
            if (writefile(l:serialized, s:localvimrc_persistence_file) == 0)
              call delete(l:backup_name)
            else
              call s:LocalVimRCError("error while writing persistence file, backup stored in '" . l:backup_name . "'")
            endif
          else
            call s:LocalVimRCError("unable to write persistence file backup '" . l:backup_name . "'")
          endif
        else
          call s:LocalVimRCError("unable to write persistence file '" . s:localvimrc_persistence_file . "'")
        endif

        " store persistence file checksum
        let s:localvimrc_persistence_file_checksum = s:LocalVimRCCalcChecksum(s:localvimrc_persistence_file)
      endif
      let s:localvimrc_persistent_data = l:persistent_data
    endif
  else
    " delete persistence file
    if filewritable(s:localvimrc_persistence_file)
      call delete(s:localvimrc_persistence_file)
    endif
  endif

  " remove old persistence data
  if exists("g:LOCALVIMRC_ANSWERS")
    unlet g:LOCALVIMRC_ANSWERS
  endif
  if exists("g:LOCALVIMRC_CHECKSUMS")
    unlet g:LOCALVIMRC_CHECKSUMS
  endif

endfunction

" Function: s:LocalVimRCClear() {{{2
"
" clear all stored data
"
function! s:LocalVimRCClear()
  let s:localvimrc_data = {}
  call s:LocalVimRCDebug(3, "cleared local data")

  let s:localvimrc_persistence_file_checksum = ""
  call s:LocalVimRCDebug(3, "cleared persistence file checksum")

  let s:localvimrc_persistent_data = {}
  call s:LocalVimRCDebug(3, "cleared persistent data")

  if filewritable(s:localvimrc_persistence_file)
    call delete(s:localvimrc_persistence_file)
    call s:LocalVimRCDebug(3, "deleted persistence file")
  endif
endfunction

" Function: s:LocalVimRCError(text) {{{2
"
" output error message
"
function! s:LocalVimRCError(text)
  echohl ErrorMsg | echom "localvimrc: " . a:text | echohl None
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
