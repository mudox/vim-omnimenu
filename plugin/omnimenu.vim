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

" omnimenu window max height in lines.
" if less lines are provided, the window will shrink accordingly.
let s:win_height = get(g:, 'g:omnimenu_win_height', 8)

" }}}1

" CORE FUNCTIONS {{{1
function s:update_buffer() " {{{2
  let lines_list = mudox#chameleon#TopModeList()

  let s:session.input = get(s:session, 'input', '')
  if !empty(s:session.input)
    call filter(lines_list, "match(v:val, '^.*' . s:session.input . '.*$') != -1")
  endif

  let s:session.lines = lines_list

  " refill buffer.
  %delete _
  call append(0, s:session.lines)
  delete _

  " resize window.
  let win_height = min([s:win_height, len(lines_list)])
  execute printf("resize %d", win_height)

  " reset current line.
  let s:session.lnum = get(s:session, 'lnum', line('$'))
  call cursor(s:session.lnum, 1)
endfunction "  }}}2

" repeatedly call getchar() to absorb all key pressings when omnimenu buffer
" is open.
function s:key_loop() " {{{2
  " list of ascii number of [0-9a-zA-Z]
  let alphnum = range(0x30, 0x39) + range(0x41, 0x5a) + range(0x61, 0x7a)

  while 1 " take charge of all key pressings.
    call s:update_buffer()
    call s:update_highlight()
    redraw!

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
      call s:action_enter()

      break
    elseif nr == 27 || nr == 3                " <Esc> or <C-c>
      " close omnimenu window and clear cmd line.
      close | redraw!
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

" main entry.
function OmniMenu() " {{{2
  botright 1new Choose_Modes
  set filetype=omnimenu

  call s:update_buffer()

  call s:key_loop()
endfunction "  }}}2

" }}}1

" ACTIONS {{{1
" after user pressed a specific combinations (e.g. <Enter>, <C-o>, <C-Enter>
" ...), a corresponding action function is called with 1 argument:
" a:context = {
"   'lnum'   : selected line number.
"   'line'   : selected line content.
"   'lines'  : list of all lines in the buffer.
"   'input'  : user input in the cmd line.
" }

function s:action_enter() " {{{2
  " close omnibuffer & clear cmd line.
  close | redraw!

  echo 'lauching: ' . s:session.line

  " clear session data.
  let s:session = {}
endfunction "  }}}2

" }}}1
