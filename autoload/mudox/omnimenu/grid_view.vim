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

  return reverse(view_lines)
endfunction "  }}}2

function mudox#omnimenu#grid_view#handle_key(provider, session, nr)     " {{{2
  if a:nr == 10                               " <C-j>
    let a:session.index -= a:session.grid.cols
    let a:session.index = max([a:session.index, 0])
  elseif a:nr == 11                           " <C-k>
    let a:session.index += a:session.grid.cols
    let a:session.index = min([a:session.index, len(a:session.data) - 1])
  elseif a:nr == 8                            " <C-h>
    let a:session.index -= 1
    let a:session.index = max([a:session.index, 0])
  elseif a:nr == 12                           " <C-l>
    let a:session.index += 1
    let a:session.index = min([a:session.index, len(a:session.data) - 1])
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
  let [line_nr, left] = a:session.grid.xy()
  let right = left + a:session.grid.cellw
  let pattern = printf('\%%%dl\%%>%dc\%%<%dc', line_nr, left, right)

  syntax clear
  execute 'syntax match Visual /' . pattern . '/'
endfunction "  }}}2

" }}}1
