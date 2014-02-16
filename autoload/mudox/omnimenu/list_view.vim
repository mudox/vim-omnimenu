" vim: foldmethod=marker

" GUARD                                                              {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" VIEW CORE FUNTIONS.                                                {{{1

function mudox#omnimenu#list_view#view(provider, session)             " {{{2
  let a:session.data = a:provider.feed(a:session)
  let a:session.list.rows = min([a:session.max_height, len(a:session.data)])

  let fmt = printf('%%-%ds', winwidth(0))

  return map(copy(a:session.data[0:a:session.list.rows - 1]),
        \ printf('printf("%s", v:val)', fmt))
endfunction " }}}2

" return 'quit' to end the fession.
" return 'handled' to suppres main key loop handling.
" return 'pass' to let main key loop handle the event.
function mudox#omnimenu#list_view#handle_key(provider, session, nr)   " {{{2
  if a:nr == 10                               " <C-j>
    let a:session.idx -= 1
    let a:session.idx = max([a:session.idx, 0])
  elseif a:nr == 11                           " <C-k>
    let a:session.idx += 1
    let a:session.idx = min([a:session.list.rows -1, a:session.idx])
  elseif a:nr == 13                           " <Enter>
    let a:session.line = getline('.')

    " provider MUST have 'on_enter' member.
    return a:provider.on_enter(a:session)
  else
    return 'pass'
  endif

  return 'handled'
endfunction "  }}}2

function mudox#omnimenu#list_view#highlight(provider, session)        " {{{2
  if !has_key(a:session.list, 'syntaxed')
    syntax clear
    call clearmatches()

    for nr in range(1, a:session.list.rows, 2)
      call s:hi_line(nr, 'OmniMenuLineB')
    endfor

    let a:session.list.syntaxed = 1
  endif
  
  " highlight current item.
  let cur_line_nr = a:session.list.rows - a:session.idx
  call s:hi_cur_line(cur_line_nr, 'Visual', a:session)
endfunction "  }}}2

" }}}1

" HELPER FUNCTIONS.                                                  {{{1

function s:hi_line(line_nr, group)                                    " {{{2
  let line_pat = printf('\%%%dl', a:line_nr)
  call matchadd(a:group, line_pat, 50)
endfunction "  }}}2

function s:hi_cur_line(line_nr, group, session)                       " {{{2
  " first clear last highlighting.
  if has_key(a:session.list, 'cur_line_hiid')
    call matchdelete(a:session.list.cur_line_hiid)
    unlet a:session.list.cur_line_hiid
  endif

  " set current line.
  let a:session.list.cur_line_hiid = matchadd(
        \ a:group, printf('\%%%dl', a:line_nr), 100)

endfunction "  }}}2

" }}}1
