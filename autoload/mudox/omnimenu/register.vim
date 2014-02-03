" vim: foldmethod=marker

" GUARD {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" construct the s:stubs which is a list of dict's of the form:
" {
"     'title'      : title,
"     'description : description,
"     'string'     : e.g. 'mudox#omnimenu#providers#top_menu#provider'
" }
function mudox#omnimenu#register#add(title, description, provider_string) " {{{2
  if !exists('s:stubs')
    let s:stubs = [{ 'title' : a:title, 'description' : a:description,
          \ 'string': a:provider_string, }]
  else
    " confliction check.
    for s in s:stubs
      if s.title ==? a:title
        throw 'omnimenu: provider title confiction.'
      endif

      if s.description ==? a:description
        throw 'omnimenu: provider description confiction.'
      endif

      if s.string ==# a:provider_string
        throw printf('omnimenu: provider [%s] already registered.',
              \ a:provider_string)
      endif
    endfor

    call add(s:stubs, { 'title' : a:title, 'description' : a:description,
          \ 'string' : a:provider_string, })
  endif
endfunction "  }}}2

function mudox#omnimenu#register#stubs() " {{{2
  lockvar! s:stubs
  return s:stubs
endfunction "  }}}2
