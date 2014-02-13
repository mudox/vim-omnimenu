" vim: foldmethod=marker

" GUARD                                                                 {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" return 'quit' to end the session.
" return 'handled' to suppres main key loop handling.
" return 'pass' to let main key loop handle the event.
function mudox#omnimenu#grid_view#view(provider, session)             " {{{1
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
        let line .= printf('%' . a:session.grid.cellw . 's', '')
      else
        let line .= printf('%-' . a:session.grid.cellw . 's',
              \ a:session.data[idx])
      endif
    endfor
    let view_lines = add(view_lines, line)
  endfor

  " add a trailing cell to each line for beautification.
   call map(view_lines,
         \ "v:val . printf('%' . a:session.grid.cellw . 's', '')")

  return view_lines
endfunction "  }}}1

function mudox#omnimenu#grid_view#handle_key(provider, session, nr)   " {{{1
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
endfunction "  }}}1

function mudox#omnimenu#grid_view#highlight(provider, session)        " {{{1
  if !exists('a:session.grid.old_cellw') ||
        \ a:session.grid.old_cellw != a:session.grid.cellw
    syntax clear

    " mosaic effect.
    " two colors
    "let [hi_0, hi_1] = ['OmniMenuMosaicCellA', 'OmniMenuMosaicCallB']
    "for r in range(1, a:session.grid.rows)
    "for c in range(a:session.grid.cols + 2)
    "let head = c * a:session.grid.cellw
    "let tail = head + a:session.grid.cellw + 2
    "call s:hi_cell(r, head, tail, hi_{c % 2})
    "endfor
    "let [hi_0, hi_1] = [hi_1, hi_0]
    "endfor

    " one colors
    for r in range(1, a:session.grid.rows)
      for c in range(r % 2, a:session.grid.cols + 2, 2)
        let head = c * a:session.grid.cellw
        let tail = head + a:session.grid.cellw + 2
        call s:hi_cell(r, head, tail, 'OmniMenuMosaicCallB')
      endfor
    endfor

    let s:old_cellw = a:session.grid.cellw
  endif

  " highlight current cell.
  let [head, row] = a:session.grid.getxy()
  let head = head * a:session.grid.cellw
  let tail = head + a:session.grid.cellw + 1

  call s:hi_cur_cell(row, head, tail, 'Visual', a:session)
  call cursor(row, head)

  "let &l:statusline = printf('idx:%d row:%d left:%d right:%d', a:session.idx, row, head, head)
  "let &l:statusline = printf('wrap: %s, filetype: %s', &l:wrap, &filetype)
  "let &l:statusline = printf('cnt: %d', s:cnt)
endfunction "  }}}1

function s:hi_cell(row, head, tail, group)                            " {{{1
  let cell_pat = printf('\%%%dl\%%>%dc.*\%%<%dc', a:row, a:head, a:tail)
  execute printf('syntax match %s +%s+', a:group, cell_pat)
endfunction "  }}}1

function s:hi_cur_cell(row, head, tail, group, session)                        " {{{1
  " first clear last current cell.
  if exists('a:session.cur_cell_hlid')
    call matchdelete(a:session.cur_cell_hlid)
    unlet a:session.cur_cell_hlid
  endif

  let cell_pat = printf('\%%%dl\%%>%dc.*\%%<%dc', a:row, a:head, a:tail)
  let a:session.cur_cell_hlid = matchadd(a:group, cell_pat, 100)
endfunction "  }}}1
