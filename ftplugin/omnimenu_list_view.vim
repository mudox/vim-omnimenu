call mudox#omnimenu#buffer_init()

" HIGHLIGHT GROUPS DEFINITIONS. {{{1

function! s:list_view_highlight() " {{{2
  let bg = synIDattr(hlID('Normal'), 'bg#')

  let bg_list = map([bg[1:2], bg[3:4], bg[5:6]], '"0x" . v:val + 0xc')
  let bg_list = map(bg_list, 'printf("%x", v:val)')
  let bg = join(bg_list, '')

  highlight link OmniMenuLineA Normal
  silent! execute printf('highlight OmniMenuLineB guibg=#%s', bg)
endfunction "  }}}2

call s:list_view_highlight()

" }}}1
