" vim: foldmethod=marker

" GUARD                                                                                {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" VARIABLES.                                                                           {{{1

" for each invocation of :OmniMenu, s:session is first cleared and then
" refilled with infomation pertains to this session.
" s:session = {
"   'max_heigh'  : max height of omnimenu window.
"   'idx'        : the index of list provided by provider.feed() that current
"                  selected..
"   'line'       : selected line content.
"   'data'       : list of lines fed from provider.
"   'buffer'     : buffer lines filled into the window.
"                  buffer.
"   'input'      : user input in the cmd line.
"   'redraw'     : flag indicating the omnimenu buffer need to regen and &
"                  redraw.
"   'view'       : currently suport 'grid' & 'list'.
"   'grid.cellw' : grid cell width in chars.
"   'grid.cols'  : grid width in cells.
"   'grid.rows'  : grid height in cells.
"   'grid.xy'    : method return [x, y] from calculated from index & grid.
" }

" after user pressed a specific key combination (e.g. <Enter>, <C-o>,
" <C-Enter> ...), a corresponding action function is called with 1 argument:
" a:provider = {
"   'title'       :
"   'description' :
"   'feed'        : source line generator.
"   'on_enter'    : user pressed enter key. return -1 to end the session.
"   'view'        : 'list' or 'grid'.
" }

" hold all registered menu providers.
let s:providers = []

" omnimenu window max height in lines.
" if less lines are provided, the window will shrink accordingly.
let s:win_max_height = get(g:, 'g:omnimenu_win_height', 8)

" menu contents providers.

" }}}1

" HELPER FUNCTIONS                                                                     {{{1

function s:inhume_cursor()                                                              " {{{2
  if !has('gui_running')
    return
  endif

  " save old settings.
  let s:cursor_id = hlID('Cursor')
  let s:cursor_fg = synIDattr(synIDtrans(s:cursor_id), 'fg')
  let s:cursor_bg = synIDattr(synIDtrans(s:cursor_id), 'bg')

  " bury it.
  highlight clear Cursor
endfunction "  }}}2

function s:exhume_cursor()                                                              " {{{2
  if !has('gui_running')
    return
  endif

  let mode = has('gui_running') ? 'gui' : 'cterm'
  let fg = !empty(s:cursor_fg) ? printf('%sfg=%s', mode, s:cursor_fg) : ''
  let bg = !empty(s:cursor_bg) ? printf('%sbg=%s', mode, s:cursor_bg) : ''

  silent execute printf('highlight Cursor %s %s', fg, bg)
endfunction "  }}}2

" return:
"   'handled' if provider reacts to the key event.
"   'pass' if provider wants ignore the key evenet.
"   'quit' it provider wants to  terminate the session.
function s:view_handle(provider, key)                                                   " {{{2
  return mudox#omnimenu#{s:session.view}_view#handle_key(
        \ a:provider, s:session, a:key)
endfunction "  }}}2

function s:new_session(provider)                                                        " {{{2
  let s:session = {
        \ 'view'       : get(a:provider, 'view', 'list'),
        \ 'input'      : '',
        \ 'max_height' : get(a:provider, 'win_height', s:win_max_height),
        \ 'idx'        : 0,
        \ 'getsel'     : function('s:getsel'),
        \ }

  " s:check_convert_provider() already guarantee that provider will has field
  " of 'view' holding an valid value.
  if a:provider.view ==# 'list'
    let s:session.list = {
          \ }
  elseif a:provider.view ==# 'grid'
    let s:session.grid = {
          \ 'getxy'     : function('s:index2xy'),
          \ }
  endif
endfunction "  }}}2

" }}}1

" CORE FUNCTIONS                                                                       {{{1
function s:update_buffer(provider)                                                      " {{{2
  let old_data_count = len(get(s:session, 'data', []))

  " re-feed data & redraw window only if needed.
  if !has_key(s:session, 'buffer') || has_key(s:session, 'redraw')
    " regain view.
    let s:session.buffer = mudox#omnimenu#{s:session.view}_view#view(
          \ a:provider, s:session)

    " reset current cell/line when sessen.data changed or in initial drawing.
    if !has_key(s:session, 'idx')
      let s:session.idx = 0
    else
      if len(s:session.data) != old_data_count
        let s:session.idx = 0
      endif
    endif

    " reset redraw flag.
    if has_key(s:session, 'redraw')
      unlet s:session.redraw
    endif

    " refill buffer.

    " switch wtite option for a readonly vim session.
    let old_write = &write
    let old_modifiable = &modifiable
    set write
    set modifiable

    %delete _
    call append(0, reverse(s:session.buffer))
    delete _

    let &write = old_write
    let &modifiable = old_modifiable

    " resize window.
    call s:resize_win(a:provider)

    normal! zb
  endif
endfunction "  }}}2

" resize omnimenu window after buffer have been refreshed.
function s:resize_win(provider)                                                         " {{{2
  if !has_key(s:session, 'prev_win_height') " first draw.
    let win_height = min([s:session.max_height, len(s:session.buffer)])
    execute printf("resize %d", win_height)
    let s:session.prev_win_height = win_height
  else
    if get(a:provider, 'shrinkable', 1) " redraw
      let s:session.max_height = get(a:provider, 'win_height',
            \ s:win_max_height)
      let win_height = min([s:session.max_height, len(s:session.buffer)])
      if s:session.prev_win_height != win_height
        execute printf("resize %d", win_height)
        let s:session.prev_win_height = win_height
      endif
    endif
  endif
endfunction "  }}}2

" core key loop.
" repeatedly call getchar() to absorb all key pressings from user when
" omnimenu buffer is open.
function s:key_loop(provider)                                                           " {{{2
  " list of ascii number of [0-9a-zA-Z]
  let normal_char = range(0x30, 0x39) + range(0x41, 0x5a) + range(0x61, 0x7a)
        \ + map(split('_/', '.\zs'), 'char2nr(v:val)')

  let s:session.input = get(s:session, 'input', '')

  while 1 " take charge of all key pressings.
    call s:update_buffer(a:provider)
    call s:update_highlight(a:provider)

    " redraw
    redraw
    echo '>>> ' . s:session.input . '_'

    let nr = getchar()

    if index(normal_char, nr) != -1           " alphanumeric
      let s:session.input = s:session.input . nr2char(nr)
      let s:session.redraw = 1
    elseif nr == "\<BS>"                      " <Backspace>
      let s:session.input = s:session.input[:-2]
      let s:session.redraw = 1
    elseif nr == 21                           " <C-u>
      let s:session.input = ''
      let s:session.redraw = 1
    elseif index([8, 10, 11, 12], nr) != -1   " <C-j,k,h,l>
      call s:view_handle(a:provider, nr)
    elseif nr == 17                           " <C-q>
      "let s:session.view = (s:session.view ==# 'list') ? 'grid' : 'list'
    elseif nr == 13                           " <Enter>
      let ret = s:view_handle(a:provider, nr)
      if ret ==# 'quit'
        break
      endif
    elseif nr == 27 || nr == 3                " <Esc> or <C-c>
      " close omnimenu window and clear cmd line.
      call mudox#omnimenu#close()
      break
    endif
  endwhile

endfunction "  }}}2

" highlight.
function s:update_highlight(provider)                                                   " {{{2
  " view specific highlightings.
  call mudox#omnimenu#{s:session.view}_view#highlight(a:provider, s:session)

  " highlight matched part against session.input
  if !exists('s:session.old_input') ||
        \ s:session.old_input !=# s:session.input
    silent! call matchdelete(s:session.machted_hlid)

    if !empty(s:session.input)
      let s:session.machted_hlid = matchadd('MoreMsg',
            \ '\V\C' . s:session.input, 200)
    endif
  endif
endfunction "  }}}2

" 'a:provider' should be a string in the form of e.g.
"     'mudox#omnimenu#top_menu#provider'.
" that points to the provider dict data structure.
" FIRST it will eval a:provider to get the underlying dictionary data
" structure, the provider script wil be loaded if not.
" THEN it will check provider's sanity. throw detailed info for any fault.
function s:check_convert_provider(provider)                                             " {{{2
  " a:provider must be a string or a dict.
  " convert string to underlying dict if needed.
  if type(a:provider) == type('')
    if a:provider !~ '\C\m^g:'
      let provider = eval('g:' . a:provider)
    else
      let provider = eval(a:provider)
    endif
  elseif type(a:provider) == type({})
    let provider = a:provider
  else
    throw 'omnimenu: invalid a:provider type, need a string or a dict.'
  endif

  " must have a 'title' field of string type.
  if !has_key(provider, 'title')
    throw printf("omnimenu: missing member 'title' in provder %s",
          \ string(provider))
  elseif type(provider.title) != type('')
    throw printf("omnimenu: provider.title should be string in %s",
          \ string(provider))
  endif

  " must have a 'description' field of string type.
  if !has_key(provider, 'description')
    throw printf("omnimenu: missing member 'description' in provder %s",
          \ string(provider))
  elseif type(provider.description) != type('')
    throw printf("omnimenu: provider.description should be string in %s",
          \ string(provider))
  endif

  " must have a 'feed' field of funcref type.
  if !has_key(provider, 'feed')
    throw printf("omnimenu: missing member 'feed' in provider %s",
          \ string(provider))
  elseif type(provider.feed) != type(function('add'))
    throw printf("omnimenu: provider.feed should be funcref in %s",
          \ string(provider))
  endif

  " if has a field 'view', must be 'list' or 'grid'
  let provider.view = get(provider, 'view', 'list')
  if index(['list', 'grid'], provider.view) == -1
    throw printf('omnimenu: invalid value [%s] for provider.view',
          \ provider.view)
  endif

  " TODO: many things to check.

  return provider
endfunction "  }}}2

" }}}1

" PUBLIC FUNCTIONS                                                                     {{{1

" main entry.
function OmniMenu(provider)                                                             " {{{2
  let provider_dict = s:check_convert_provider(a:provider)

  " reset for a new session.
  call s:new_session(provider_dict)

  call s:inhume_cursor()

  " open a new window in the user specified way, 'new' if not.
  " suppress any autocmd events.
  silent execute printf("noautocmd %s __mudox__omnimenu__",
        \ get(provider_dict, 'open_way', 'botright 1new'))

  " ftplugin/omnimenu.vim will be sourced.
  let &filetype = printf('omnimenu_%s_view', s:session.view)

  " set status line & cursor.
  let status_string = 'OmniMenu > ' . provider_dict['title']
  let &l:statusline = status_string

  " entry main key loop.
  call s:key_loop(provider_dict)

  call s:exhume_cursor()
endfunction "  }}}2

" }}}1

" SESSION MEMBER FUNCTIONS                                                             {{{1

function s:index2xy() dict                                                              " {{{2
  " NOTE: self here points to session.gird.
  let x = s:session.idx % self.cols
  let y = self.rows - (s:session.idx / self.cols)
  return [x, y]
endfunction "  }}}2

function s:getsel() dict                                                                " {{{2
  " NOTE: self here points to session.
  return self.data[self.idx]
endfunction "  }}}2

" }}}1

" COMMANDS & MAPPINGS                                                                  {{{1

" command & mapping to stat 'top_menu' session.
command -narg=0 OmniMenuTopMenu call OmniMenu(
      \ mudox#omnimenu#providers#top_menu#provider)
nnoremap <silent> <Plug>(OmniMenu_TopMenu) :<C-U>OmniMenuTopMenu<Cr>

" }}}1
