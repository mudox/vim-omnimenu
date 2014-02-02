" vim: foldmethod=marker

" GUARD {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

let NewOmniMenu = function('mudox#omnimenu#new')
let RegisterMenuProvder = function('mudox#omnimenu#register_provider')

" COMMANDS & MAPPINGS {{{1
command -narg=0 OmniMenuTopMenu call mudox#omnimenu#new(
      \ mudox#omnimenu#providers#top_menu#provider)
nnoremap <silent> <Plug>(OmniMenu_TopMenu) :<C-U>OmniMenuTopMenu<Cr>

command -narg=0 ChamStartup call mudox#omnimenu#new(
      \ mudox#omnimenu#providers#cham_startup#provider)
nnoremap <silent> <Plug>(OmniMenu_ChamStartup) :<C-U>ChamStartup<Cr>
" }}}1

let g:omnimenu_providers = [
      \ mudox#omnimenu#providers#cham_startup#provider  ,
      \ mudox#omnimenu#providers#cham_edit_meta#provider,
      \ mudox#omnimenu#providers#cham_edit_mode#provider,
      \ ]

for p in g:omnimenu_providers
  call mudox#omnimenu#register_provider(p)
endfor
