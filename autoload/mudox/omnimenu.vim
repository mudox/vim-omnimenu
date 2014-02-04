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
    quit
  else
    close | redraw | echo
  endif
endfunction "  }}}2

" }}}1
