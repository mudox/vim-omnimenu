" vim: foldmethod=marker

" GUARD                                                    {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" GRID VIEW.                                               {{{1

function mudox#omnimenu#grid_view#view(provider, session)   " {{{2
  let a:session.data = a:provider.feed(a:session)

  " get cell width.
  let a:session.grid.cellw = 0
  for x in a:session.data
    if len(x) > a:session.grid.cellw
      let a:session.grid.cellw = len(x)
    endif
  endfor
  let a:session.grid.cellw += 1 " append a trailing space.

  " grid size.
  let a:session.grid.cols = (winwidth(a:session.winnr) - 2) /
        \ a:session.grid.cellw
  let a:session.grid.rows = float2nr(ceil(len(a:session.data) * 1.0 /
        \ a:session.grid.cols))

  " construct grid lines.
  let view_lines = []
  for row in range(a:session.grid.rows)
    let line = ''
    for column in range(a:session.grid.cols)
      let idx = row * a:session.grid.cols + column
      if idx >= len(a:session.data)
        let line .= printf('%-' . a:session.grid.cellw . 's', '')
      else
        let line .= printf('%-' . a:session.grid.cellw . 's',
              \ a:session.data[idx])
      endif
    endfor
    let view_lines = add(view_lines, line)
  endfor

  return view_lines
endfunction "  }}}2

function mudox#omnimenu#grid_view#handle_key(provider, session, nr)     " {{{2
  if a:nr == 10                               " <C-j>
    if (a:session.idx - a:session.grid.cols) >= 0
      let a:session.idx -= a:session.grid.cols
    endif
  elseif a:nr == 11                           " <C-k>
    if (a:session.idx + a:session.grid.cols) < len(a:session.data)
      let a:session.idx += a:session.grid.cols
    endif
  elseif a:nr == 8                            " <C-h>
    if (a:session.idx - 1) >= 0
      let a:session.idx -= 1
    endif
  elseif a:nr == 12                           " <C-l>
    if (a:session.idx + 1) < len(a:session.data)
      let a:session.idx += 1
    endif
  elseif a:nr == 13                           " <Enter>
    let a:session.line = getline('.')

    " provider MUST have 'on_enter' member.
    return a:provider.on_enter(a:session)
  else
    return 'pass'
  endif

  return 'handled'
endfunction "  }}}2

function mudox#omnimenu#grid_view#highlight(provider, session)       " {{{2
  let [lo, row] = a:session.grid.xy()
  let lo = lo * a:session.grid.cellw
  let hi = lo + a:session.grid.cellw + 1
  let pattern = printf('\%%%dl\%%>%dc.*\%%<%dc', row, lo, hi)

  execute 'syntax match Visual +' . pattern . '+'
  call cursor(lo, row)

  "let &l:statusline = printf('idx:%d row:%d left:%d right:%d', a:session.idx, row, lo, hi)
endfunction "  }}}2

" }}}1
