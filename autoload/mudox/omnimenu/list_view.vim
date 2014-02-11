" vim: foldmethod=marker

" GUARD                                                                 {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

function mudox#omnimenu#list_view#view(provider, session)             " {{{1
  let a:session.data = copy(a:provider.feed(a:session))
  return reverse(a:session.data)
endfunction "  }}}1

" return 'quit' to end the session.
" return 'handled' to suppres main key loop handling.
" return 'pass' to let main key loop handle the event.
function mudox#omnimenu#list_view#handle_key(provider, session, nr)   " {{{1
  if a:nr == 10                               " <C-j>
    let a:session.index -= 1
    let a:session.index = max([a:session.index, 0])
  elseif a:nr == 11                           " <C-k>
    let a:session.index += 1
    let a:session.index = min([len(a:session.data) - 1, a:session.index])
  elseif a:nr == 13                           " <Enter>
    let a:session.line = getline('.')

    " provider MUST have 'on_enter' member.
    return a:provider.on_enter(a:session)
  else
    return 'pass'
  endif
endfunction "  }}}1

function mudox#omnimenu#list_view#highlight(provider, session)        " {{{1
  " set current line.
  call cursor(line('$') - a:session.index, 0)
endfunction "  }}}1
