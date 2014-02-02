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
  let data_list = a:provider.source_generator(s:session)

  let s:session.input = get(s:session, 'input', '')
  if !empty(s:session.input)
    call filter(data_list, "match(v:val, '^.*' . s:session.input . '.*$') != -1")
  endif

  let s:session.lines = data_list

  " refill buffer.
  %delete _
  call append(0, s:session.lines)
  delete _

  " resize window.
  let win_height = min([s:win_height, len(data_list)])
  execute printf("resize %d", win_height)

  " relocate current line.
  let s:session.lnum = get(s:session, 'lnum', line('$'))
  call cursor(s:session.lnum, 1)
  normal! zb
endfunction "  }}}2

" repeatedly call getchar() to absorb all key pressings when omnimenu buffer
" is open.
function s:key_loop(provider) " {{{2
  " list of ascii number of [0-9a-zA-Z]
  let alphnum = range(0x30, 0x39) + range(0x41, 0x5a) + range(0x61, 0x7a)

  let s:session.input = get(s:session, 'input', '')

  while 1 " take charge of all key pressings.
    call s:update_buffer(a:provider)
    call s:update_highlight()
    redraw

    echo '>>> ' . s:session.input
    let nr = getchar()

    if index(alphnum, nr) != -1               " alphanumeric
      let s:session.input = s:session.input . nr2char(nr)
    elseif nr == "\<BS>"                      " <Backspace>
      let s:session.input = s:session.input[:-2]
    elseif nr == 21                           " <C-u>
      let s:session.input = ''
    elseif nr == 10                           " <C-j>
      let s:session.lnum = min([line('$'), s:session.lnum + 1])
    elseif nr == 11                           " <C-k>
      let s:session.lnum = max([s:session.lnum - 1, 1])
    elseif nr == 8                            " <C-k>
      " TODO:
    elseif nr == 12                           " <C-l>
      " TODO:
    elseif nr == 13                           " <Enter>
      let s:session.lnum = line('.')
      let s:session.line = getline('.')

      if has_key(a:provider, 'action_enter')
        call a:provider.action_enter(s:session)
      else
        call s:action_enter(s:session)
      endif

      break
    elseif nr == 27 || nr == 3                " <Esc> or <C-c>
      " close omnimenu window and clear cmd line.
      close | redraw
      echoh WarningMsg
      echo '* omnimenu: Canceled *'
      echoh None
      let s:session = {}
      break
    endif
  endwhile
endfunction "  }}}2

" highlight part of each line that match against user input.
function s:update_highlight() " {{{2
  syntax clear
  if !empty(s:session.input)
    execute 'syntax match OmniMenuMatched /' . s:session.input . '/'
  endif
endfunction "  }}}2

" check provider's sanity. throw specific info in case any fault.
function s:check_provider(provider) " {{{2
  " must have a 'title' field of string type.
  if !has_key(a:provider, 'title')
    throw printf("omnimenu: missing member 'title' in provder %s",
          \ string(a:provider))
  elseif type(a:provider.title) != type('')
    throw printf("omnimenu: provider.title should be string in %s",
          \ string(a:provider))
  endif

  " must have a 'description' field of string type.
  if !has_key(a:provider, 'description')
    throw printf("omnimenu: missing member 'description' in provder %s",
          \ string(a:provider))
  elseif type(a:provider.description) != type('')
    throw printf("omnimenu: provider.description should be string in %s",
          \ string(a:provider))
  endif

  " must have a 'source_generator' field of funcref type.
  if !has_key(a:provider, 'source_generator')
    throw printf("omnimenu: missing member 'source_generator' in provder %s",
          \ string(a:provider))
  elseif type(a:provider.source_generator) != type(function('add'))
    throw printf("omnimenu: provider.source_generator should be funcref in %s",
          \ string(a:provider))
  endif

  " TODO: many things to check.
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

function s:action_enter(session) " {{{2
  " close omnibuffer & clear cmd line.
  close | redraw

  echo 'You choosed: ' . a:session.line
endfunction "  }}}2

" }}}1

" PUBLIC FUNCTIONS {{{1

" a:provider should be a dictioiary containing proper fields.
" omnimenu will deep lock it on receiving.
function mudox#omnimenu#register_provider(provider) " {{{2
  call s:check_provider(a:provider)

  " lock recursively to at most 100 levels.
  unlockvar! s:providers
  let s:providers = add(s:providers, a:provider)
  lockvar! s:providers
endfunction "  }}}2

" main entry.
function mudox#omnimenu#new(provider) " {{{2
  " verify argument.
  call s:check_provider(a:provider)

  " reset for a new session.
  let s:session = {}

  let buffer_name = 'OmniMenu > ' . a:provider.title
  " unamed buffer opened at bottom-most.
  execute printf("botright 1new %s", escape(buffer_name, ' '))
  " ftplugin/omnimenu.vim will be sourced.
  set filetype=omnimenu

  " entry main key loop.
  call s:key_loop(a:provider)
endfunction "  }}}2

" return registered providers.
function mudox#omnimenu#providers() " {{{2
  return s:providers
endfunction "  }}}2
" }}}1
