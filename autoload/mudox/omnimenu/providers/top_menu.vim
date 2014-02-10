" vim: foldmethod=marker

" GUARD {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" PROVIDER MEMEBERS {{{1

function s:on_enter(session) " {{{2
  " no valid mode selected, no-ops.
  if a:session.line =~# '^\*\* Oops'
    let a:session.quit = 0
    return
  endif

  " close omnibuffer & clear cmd line.
  call mudox#omnimenu#close()

  let selected_provider = s:provider_map[a:session.line]
  call OmniMenu(selected_provider)
endfunction "  }}}2

function s:feed(session) " {{{2
  if !exists('s:full_line_list')
    call s:init()
  endif

  if !empty(a:session.input)
    let filtered_line_list = filter(copy(s:full_line_list),
          \ printf("match(v:val, '\\c%s') != -1", a:session.input))

    if empty(filtered_line_list)
      return ['** Oops, you need select an existing mode **']
    else
      return filtered_line_list
    endif
  else
    return s:full_line_list
  endif
endfunction "  }}}2

" }}}1

" HELPER FUNCTIONS {{{1

" initialize s:provider_map
function s:init() " {{{2
  let s:provider_map = {}

  let title_column_max_width = 0
  for p in mudox#omnimenu#register#stubs()
    let title_column_max_width = max([title_column_max_width, len(p.title)])
  endfor

  for p in mudox#omnimenu#register#stubs()
    let key = printf("%-" . title_column_max_width . "s : %s",
          \ p.title, p.description)
    let s:provider_map[key] = p.string
  endfor

  let s:full_line_list = keys(s:provider_map)

  lockvar! s:provider_map
endfunction "  }}}2

" }}}1

" make the provider data structure.
let mudox#omnimenu#providers#top_menu#provider = {
      \ 'title'             : 'Top',
      \ 'description'       : 'omnimenu top level menu, a menu of available menus.',
      \ 'feed'              : function('s:feed'),
      \ 'on_enter'          : function('s:on_enter'),
      \ }
