if exists("s:loaded") || &cp || version < 700
    finish
endif
let s:loaded = 1

" script wide variables. {{{1
let s:inputed = ''
let s:win_height = 8
" }}}1

function s:update_buffer() " {{{2
  let lines_list = mudox#chameleon#TopModeList()

  if !empty(s:inputed)
    call filter(lines_list, "match(v:val, '^.*' . s:inputed . '.*$') != -1")
  endif

  " refill buffer.
  %delete _
  call append(0, lines_list)
  delete _

  " resize window.
  let win_height = min([s:win_height, len(lines_list)])
  execute printf("resize %d", win_height)

  " reset current line.
  let b:logical_cur_line = get(b:, 'logical_cur_line', 0)
  call cursor(line('$') - b:logical_cur_line, 1)
endfunction "  }}}2

function s:key_loop() " {{{2
  " list of ascii number of [0-9a-zA-Z]
  let alphnum = range(0x30, 0x39) + range(0x41, 0x5a) + range(0x61, 0x7a)

  while 1 " take charge of all key pressings.

    call s:update_buffer()
    call s:update_highlight()
    redraw

    echo '>>> ' . s:inputed
    let nr = getchar()

    if index(alphnum, nr) != -1        " alphanumeric
      let s:inputed = s:inputed . nr2char(nr)
    elseif nr == "\<BS>"                      " <Backspace>
      let s:inputed = s:inputed[:-2]
    elseif nr == 21                           " <C-u>
      let s:inputed = ''
    elseif nr == 10                           " <C-j>
      let b:logical_cur_line = max([0, b:logical_cur_line - 1])
    elseif nr == 11                           " <C-k>
      let b:logical_cur_line = min([b:logical_cur_line + 1, line('$') - 1])
    elseif nr == 8                            " <C-k>
    elseif nr == 12                           " <C-l>

    elseif nr == 27 || nr == 3                " <Esc> or <C-c>
      let s:inputed = ''
      break
    endif

  endwhile

  redraw
  echo 'Byebye !!!'
endfunction "  }}}2

function s:update_highlight() " {{{2
  syntax clear
  if !empty(s:inputed)
    execute 'syntax match OmniMenuMatched /' . s:inputed . '/'
  endif
endfunction "  }}}2

function OmniMenu() " {{{2
  botright 1new Choose_Modes
  set filetype=omnimenu

  call s:update_buffer()


  call s:key_loop()

  close
endfunction "  }}}2
