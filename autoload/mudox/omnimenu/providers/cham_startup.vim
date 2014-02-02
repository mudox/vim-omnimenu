" vim: foldmethod=marker

" GUARD {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" PROVIDER MEMEBERS " {{{1

function s:action_enter(session) " {{{2
  " close omnibuffer & clear cmd line.
  close | redraw

  echo 'lauching: ' . a:session.line
  call writefile([a:session.line], g:mdx_chameleon_cur_mode_file)
  py import subprocess
  py subprocess.Popen('gvim')

endfunction "  }}}2

function s:source_generator(session) " {{{2
  let line_list = mudox#chameleon#TopModeList()

  if !empty(a:session.input)
    call filter(line_list, "match(v:val, '^.*' . a:session.input . '.*$') != -1")
  endif

  return line_list
endfunction "  }}}2

" }}}1

" make the provider data structure.
let mudox#omnimenu#providers#cham_startup#provider = {
      \ 'title'             : 'Startup',
      \ 'description'       : 'start gvim in new mode',
      \ 'source_generator'  : function('s:source_generator'),
      \ 'action_enter'      : function('s:action_enter'),
      \ }
let s:provider = mudox#omnimenu#providers#cham_startup#provider

call mudox#omnimenu#register_provider(s:provider)
