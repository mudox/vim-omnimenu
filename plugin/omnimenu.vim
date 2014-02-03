" vim: foldmethod=marker

" GUARD {{{1
if exists("s:loaded") || &cp || version < 700
  finish
endif
let s:loaded = 1
" }}}1

" VARIABLES. {{{1

" for each invocation of :OmniMenu, s:session is first cleared and then
" refilled with infomation pertain to this session.
" for details about it's memebers see comments under setion 'ACTIONS' below.
let s:session = {}

" hold all registered menu providers.
let s:providers = []

" omnimenu window max height in lines.
" if less lines are provided, the window will shrink accordingly.
let s:win_height = get(g:, 'g:omnimenu_win_height', 8)

" menu contents providers.

" }}}1

" CORE FUNCTIONS {{{1
function s:update_buffer(provider) " {{{2
  let old_line_num = len(get(s:session, 'lines', []))

  " re-feed data & redraw window only if needed.
  if !has_key(s:session, 'lines') || has_key(s:session, 'filter')
    " re-feed source data.
    let s:session.lines = a:provider.feed(s:session)

    " reset filter flag.
    if has_key(s:session, 'filter')
      unlet s:session.filter
    endif

    " refill buffer.
    %delete _
    call append(0, s:session.lines)
    delete _

    " resize window.
    let win_height = min([s:win_height, len(s:session.lines)])
    execute printf("resize %d", win_height)
  endif

  " relocate current line.
  " put current line at the last line in the beginning.
  " if the number of buffer lines changed, reset currrent line to the last
  " line.
  if !has_key(s:session, 'lnum')
    let s:session.lnum = line('$')
  else
    if len(s:session.lines) != old_line_num
      let s:session.lnum = line('$')
    endif
  endif

  call cursor(s:session.lnum, 1)
  normal! zb
endfunction "  }}}2

" repeatedly call getchar() to absorb all key pressings when omnimenu buffer
" is open.
function s:key_loop(provider) " {{{2
  " list of ascii number of [0-9a-zA-Z]
  let normal_char = range(0x30, 0x39) + range(0x41, 0x5a) + range(0x61, 0x7a)
        \ + map(split('_/', '.\zs'), 'char2nr(v:val)')

  let s:session.input = get(s:session, 'input', '')

  while 1 " take charge of all key pressings.
    call s:update_buffer(a:provider)
    call s:update_highlight()

    " redraw
    redraw
    echo '>>> ' . s:session.input

    let nr = getchar()

    if index(normal_char, nr) != -1               " alphanumeric
      let s:session.input = s:session.input . nr2char(nr)
      let s:session.filter = 1
    elseif nr == "\<BS>"                      " <Backspace>
      let s:session.input = s:session.input[:-2]
      let s:session.filter = 1
    elseif nr == 21                           " <C-u>
      let s:session.input = ''
      let s:session.filter = 1
    elseif nr == 10                           " <C-j>
      let s:session.lnum = min([line('$'), s:session.lnum + 1])
    elseif nr == 11                           " <C-k>
      let s:session.lnum = max([s:session.lnum - 1, 1])
    elseif nr == 8                            " <C-h>
      " TODO:
    elseif nr == 12                           " <C-l>
      " TODO:
    elseif nr == 13                           " <Enter>
      let s:session.lnum = line('.')
      let s:session.line = getline('.')

      if has_key(a:provider, 'on_enter')
        call a:provider.on_enter(s:session)
      else
        call s:default_on_enter(s:session)
      endif

      break
    elseif nr == 27 || nr == 3                " <Esc> or <C-c>
      " close omnimenu window and clear cmd line.
      "close | redraw | echo
      call mudox#omnimenu#close()
      break
    endif
  endwhile
endfunction "  }}}2

" highlight part of each line that match against user input.
function s:update_highlight() " {{{2
  syntax clear
  if !empty(s:session.input)
    execute 'syntax match OmniMenuMatched :' . s:session.input . ':'
  endif
endfunction "  }}}2

" 'a:provider' should be a string in the form of e.g.
"     'mudox#omnimenu#top_menu#provider'.
" that points to the provider dict data structure.
" FIRST it will eval a:provider to get the underlying dictionary data
" structure, the provider script wil be loaded if not.
" THEN it will check provider's sanity. throw detailed info for any fault.
function s:check_convert_provider(provider) " {{{2
  " a:provider must be a string or a dict.
  " convert string to underlying dict if needed.
  if type(a:provider) == type('')
    if a:provider !~ '\C\m^g:'
      let provider_string = 'g:' . a:provider
    endif
    let provider = eval(provider_string)
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
    throw printf("omnimenu: missing member 'feed' in provder %s",
          \ string(provider))
  elseif type(provider.feed) != type(function('add'))
    throw printf("omnimenu: provider.feed should be funcref in %s",
          \ string(provider))
  endif

  " TODO: many things to check.

  return provider
endfunction "  }}}2

" }}}1

" DEFAULT ACTION FUNCTIONS {{{1

" after user pressed a specific combinations (e.g. <Enter>, <C-o>, <C-Enter>
" ...), a corresponding action function is called with 1 argument:
" a:session = {
"   'lnum'   : selected line number.
"   'line'   : selected line content.
"   'lines'  : list of all lines in the buffer.
"   'input'  : user input in the cmd line.
" }

function s:default_on_enter(session) " {{{2
  " close omnibuffer & clear cmd line.
  close | redraw

  echo 'You choosed: ' . a:session.line
endfunction "  }}}2

" }}}1

" PUBLIC FUNCTIONS {{{1

" main entry.
function OmniMenu(provider) " {{{2
  let provider = s:check_convert_provider(a:provider)

  " reset for a new session.
  let s:session = {}

  let buffer_name = 'OmniMenu > ' . provider['title']
  " unamed buffer opened at bottom-most.
  silent execute printf("noautocmd botright 1new %s", escape(buffer_name, ' '))
  " ftplugin/omnimenu.vim will be sourced.
  set filetype=omnimenu

  " entry main key loop.
  call s:key_loop(provider)
endfunction "  }}}2

" }}}1

" COMMANDS & MAPPINGS {{{1
command -narg=0 OmniMenuTopMenu call OmniMenu(
      \ mudox#omnimenu#providers#top_menu#provider)
nnoremap <silent> <Plug>(OmniMenu_TopMenu) :<C-U>OmniMenuTopMenu<Cr>

command -narg=0 ChamStartup call OmniMenu(
      \ mudox#omnimenu#providers#cham_startup#provider)
nnoremap <silent> <Plug>(OmniMenu_ChamStartup) :<C-U>ChamStartup<Cr>
" }}}1
