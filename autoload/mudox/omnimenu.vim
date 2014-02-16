" vim: foldmethod=marker

" GUARD {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" HELPER FUNCTIONS {{{1

" used to close omnimenu window when terminating a omnimenu session.
function mudox#omnimenu#close() " {{{2
  " if omnimenu is the last window, quit the vim.
  if tabpagenr('$') == 1 && winnr('$') == 1
    quit!
  else
    call s:leave()

    close! | redraw | echo
    wincmd p
  endif
endfunction "  }}}2

" initial settings for new opened omnimenu window & buffer.
function mudox#omnimenu#buffer_init() " {{{2
  setlocal buftype=nofile
  setlocal noswapfile
  setlocal bufhidden=wipe
  setlocal nobuflisted

  setlocal nocursorcolumn
  setlocal nocursorline
  setlocal nowrap
  setlocal nonumber
  setlocal nolist

  if &timeout
    let b:old_timeoutlen = &timeoutlen
    set timeoutlen=10
  endif
endfunction "  }}}2

function s:leave() " {{{2
  let &timeoutlen = b:old_timeoutlen
endfunction "  }}}2

" }}}1
