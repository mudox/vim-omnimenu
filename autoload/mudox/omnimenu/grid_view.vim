" vim: foldmethod=marker

" GUARD                                                    {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" LIST VIEW.                                               {{{1

function mudox#omnimenu#view#list_view(provider)            " {{{2
  " TODO:
endfunction "  }}}2

function mudox#omnimenu#view#list_handle_keys(provider)     " {{{2
  " TODO:
endfunction "  }}}2

function mudox#omnimenu#view#list_highlight(provider)       " {{{2
  " TODO:
endfunction "  }}}2

" }}}1

" GRID VIEW.                                               {{{1

function mudox#omnimenu#view#grid_view(provider, session)   " {{{2
  let raw_lines = a:provider.feed(a:session)
  let view_lines = []

  " get cell width.
  let a:session.grid.cellw = 0
  for x in raw_lines
    if len(x) > a:session.grid.cellw
      let a:session.grid.cellw = len(x)
    endif
  endfor

  " grid size.
  let s:session.grid.cols = winwidth(a:session.winnr) / (a:session.grid.cellw + 1)
  let s:session.grid.rows = float2nr(ceil(len(raw_lines) * 1.0 /
        \ s:session.grid.cols))

  " grid lines.
  for r in range(s:session.grid.rows)
    let view_lines = add(view_lines, '')
    for c in range(s:session.grid.cols)
      let index = r * s:session.grid.cols + c
      if index == len(raw_lines)
        break
      endif

      if c == 0
        let view_lines[-1] .=
              \ printf('%-' . a:session.grid.cellw . 's ', raw_lines[index])
      else
        let view_lines[-1] .=
              \ printf('%-' . a:session.grid.cellw . 's ', raw_lines[index])
      endif
    endfor
  endfor

  return reverse(view_lines)
endfunction "  }}}2

function mudox#omnimenu#view#index2xy(index, session)       " {{{2
  let x = a:index % a:session.grid.cols
  let y = a:index / a:session.grid.cols
  return [x, y]
endfunction "  }}}2

function mudox#omnimenu#view#xy2index(index, session)       " {{{2
  return y * a:session.grid.cols + x
endfunction "  }}}2

function mudox#omnimenu#view#grid_handle_keys(provider)     " {{{2
  " TODO:
endfunction "  }}}2

function mudox#omnimenu#view#grid_highlight(provider)       " {{{2
  " TODO:
endfunction "  }}}2

" }}}1
