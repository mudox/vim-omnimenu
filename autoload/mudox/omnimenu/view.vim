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

function mudox#omnimenu#view#list_highlight(provider)     " {{{2
  " TODO:
endfunction "  }}}2

" }}}1

" MOSIAC VIEW.                                             {{{1

function mudox#omnimenu#view#mosaic_view(provider, session)          " {{{2
  let raw_lines = a:provider.feed(a:session)
  let view_lines = []

  " get cell width.
  let cell_width = 0
  for x in raw_lines
    if len(x) > cell_width
      let cell_width = len(x)
    endif
  endfor

  let column_count = winwidth(a:session.winnr) / (cell_width + 1)
  let row_count = float2nr(ceil(len(raw_lines) * 1.0 / column_count))

  for r in range(row_count)
    let view_lines = add(view_lines, '')
    for c in range(column_count)
      let index = r * column_count + c
      if index == len(raw_lines)
        break
      endif

      if c == 0 
        let view_lines[-1] .= 
              \ printf('%-' . cell_width . 's ', raw_lines[index])
      else
        let view_lines[-1] .=
              \ printf('%-' . cell_width . 's ', raw_lines[index])
      endif
    endfor
  endfor

  return reverse(view_lines)
endfunction "  }}}2

function mudox#omnimenu#view#mosaic_handle_keys(provider)   " {{{2
  " TODO:
endfunction "  }}}2

function mudox#omnimenu#view#mosaic_highlight(provider)     " {{{2
  " TODO:
endfunction "  }}}2

" }}}1

