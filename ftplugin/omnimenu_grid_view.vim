setlocal buftype=nofile
setlocal noswapfile
setlocal bufhidden=wipe
setlocal nobuflisted
setlocal nowrap

" GRID VIEW HIGHLIGHT SETTING. {{{1

" mosiac effect.
function! s:mosaic_highlight() " {{{2
  let bg = synIDattr(hlID('Normal'), 'bg#')

  let bg_list = map([bg[1:2], bg[3:4], bg[5:6]], '"0x" . v:val + 0xc')
  let bg_list = map(bg_list, 'printf("%x", v:val)')
  let bg = join(bg_list, '')

  highlight link OmniMenuMosaicCellA Normal
  silent! execute printf('highlight OmniMenuMosaicCallB guibg=#%s', bg)
endfunction "  }}}2

call s:mosaic_highlight()

" }}}1
