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

  let selected_meta = a:session.line
  call g:chameleon.editMeta(selected_meta)
endfunction "  }}}2

function s:source_generator(session) " {{{2
  if !exists('s:full_metas_avail')
    call s:init()
  endif

  if !empty(a:session.input)
    let filtered_line_list = filter(copy(s:full_metas_avail),
          \ "match(v:val, '\\c^.*\\V' . a:session.input . '\\m.*$') != -1")
    return filtered_line_list
  else
    return s:full_metas_avail
  endif
endfunction "  }}}2

" }}}1

" HELPER FUNCTIONS {{{1

" initialize s:full_metas_avail
function s:init() " {{{2
  let s:full_metas_avail = g:chameleon.metasAvail()
  lockvar! s:full_metas_avail
endfunction "  }}}2

" }}}1

" make the provider data structure.
let mudox#omnimenu#providers#cham_edit_meta#provider = {
      \ 'title'             : 'Edit Chameleon Meda',
      \ 'description'       : 'edit/create chameleon meta',
      \ 'source_generator'  : function('s:source_generator'),
      \ 'action_enter'      : function('s:action_enter'),
      \ }
let s:provider = mudox#omnimenu#providers#cham_edit_meta#provider
