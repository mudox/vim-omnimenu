" vim: foldmethod=marker

" GUARD {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" PROVIDER MEMEBERS {{{1

function s:action_enter(session) " {{{2
  " close omnibuffer & clear cmd line.
  close | redraw

  let selected_provider = s:provider_map[a:session.line]
  call mudox#omnimenu#new(selected_provider)
endfunction "  }}}2

function s:source_generator(session) " {{{2
  if !exists('s:full_line_list')
    call s:init()
    let s:full_line_list = keys(s:provider_map)
  endif

  if !empty(a:session.input)
    let line_list = filter(copy(s:full_line_list),
          \ printf("match(v:val, '\\c%s') != -1", a:session.input))
    return line_list
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
  for p in mudox#omnimenu#providers()
    let title_column_max_width = max([title_column_max_width, len(p.title)])
  endfor

  for p in mudox#omnimenu#providers()
    let key = printf("%-" . title_column_max_width . "s : %s",
          \ p.title, p.description)
    let s:provider_map[key] = p
  endfor

  lockvar! s:provider_map
endfunction "  }}}2

" }}}1

" make the provider data structure.
let mudox#omnimenu#providers#top_menu#provider = {
      \ 'title'             : 'Top',
      \ 'description'       : 'omnimenu top level menu, a menu of available menus.',
      \ 'source_generator'  : function('s:source_generator'),
      \ 'action_enter'      : function('s:action_enter'),
      \ }
let s:provider = mudox#omnimenu#providers#top_menu#provider

