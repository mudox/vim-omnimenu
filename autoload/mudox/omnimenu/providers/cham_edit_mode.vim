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

  let selected_mode = a:session.line
  call g:chameleon.editMode(selected_mode)
endfunction "  }}}2

function s:source_generator(session) " {{{2
  if !exists('s:full_modes_avail')
    call s:init()
  endif

  if !empty(a:session.input)
    let filtered_line_list = filter(copy(s:full_modes_avail),
          \ "match(v:val, '\\c^.*\\V' . a:session.input . '\\m.*$') != -1")
    return filtered_line_list
  else
    return s:full_modes_avail
  endif
endfunction "  }}}2

" }}}1

" HELPER FUNCTIONS {{{1

" initialize s:full_modes_avail
function s:init() " {{{2
  let s:full_modes_avail = g:chameleon.modesAvail()
  lockvar! s:full_modes_avail
endfunction "  }}}2

" }}}1

" make the provider data structure.
let mudox#omnimenu#providers#cham_edit_mode#provider = {
      \ 'title'             : 'Edit Chameleon Mode',
      \ 'description'       : 'edit/create chameleon mode',
      \ 'source_generator'  : function('s:source_generator'),
      \ 'action_enter'      : function('s:action_enter'),
      \ }
let s:provider = mudox#omnimenu#providers#cham_edit_mode#provider
