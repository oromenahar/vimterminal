function! vimterminal#DisplayTime(...)
    if a:0 > 0 && (a:1 == "d" || a:1 == "t")
        if a:1 == "d"
            echo strftime("%b %d")
        elseif a:1 == "t"
            echo strftime("%H:%M")
        endif
    else
        echo strftime("%b %d %H:%M:%S")
    endif
endfunction

let g:vimterminal_buffer = 0
let g:vimterminal_buffers = {}

function! vimterminal#startswith(short, long) abort
    if len(a:long) < len(a:short)
        return 0
    endif
    return a:long[0:len(a:short)-1] == a:short
endfunction


function! vimterminal#GetPathFromFile()
    " filename of the current buffer
    let l:file = @%
    let l:buf_paths = keys(g:vimterminal_buffers)
    for buf_path in l:buf_paths
        if vimterminal#startswith(buf_path, l:file)
            return buf_path
        endif
    endfor
    return ""
endfunction

function! vimterminal#AskForPathFromUser()
    let l:path = input("Which path? ")
    if l:path == ""
        " user pressed key combination, but don't need a terminal
        return ""
    endif
    return l:path
endfunction

function! vimterminal#AskForPathFromDict(cmds)
    let l:msg = "Choose 0) Custom, "
    let l:paths = keys(a:cmds)
    let l:count = 1
    for l:path in l:paths
        let l:msg .= l:count . ") " . l:path . ", "
        let l:count += + 1
    endfor
    let l:number = input(l:msg . ":")
    if l:number =~# '^\d\+$'
        if l:number == 0
            return ""
        elseif len(l:paths) >= l:number - 1 && l:number >= 1
            return l:paths[l:number - 1]
        endif
    endif
    return ""
endfunction


function! vimterminal#GetCommandsFromFile()
    if !filereadable(getcwd() . '/.vimterm.txt')
        return {}
    endif
    let l:path_commands = readfile(getcwd() . '/.vimterm.txt')
    let l:cmds = {}
    for l:path_command in l:path_commands
        let l:pc = split(l:path_command, ":", 1)
        if len(l:pc) >= 2
            let l:paths = split(l:pc[0], ";")
            let l:first = l:paths[0]
            for l:p in l:paths
                let l:cmds[l:p] = { 'command': l:pc[1], 'main_path': l:first }
            endfor
        endif
    endfor
    return l:cmds
endfunction

function! vimterminal#ToggleTerm()
    let l:currentwinnr = winnr()
    let l:wincount = winnr("$")
    let l:i = 1
    while i <= l:wincount
        let l:bufname = bufname(winbufnr(i))
        if vimterminal#startswith("!/VIMTERM/", l:bufname)
            execute bufwinnr(winbufnr(i)).."hide"
            return
        endif
        let l:i += 1
    endwhile
    let l:cmds = {}
    let l:path = vimterminal#GetPathFromFile()
    if l:path == ""
        let l:cmds = vimterminal#GetCommandsFromFile()
        let l:path = vimterminal#AskForPathFromDict(l:cmds)
        if l:path == ""
            let l:path = vimterminal#AskForPathFromUser()
            if l:path == ""
                " user pressed key combination, but don't need a terminal
                return
            endif
        endif
        let g:vimterminal_buffers[l:path] = { 'bufnr': -1, 'main_path': l:cmds[l:path]['main_path'] }
    endif
    call vimterminal#GetTermBack(l:path, l:cmds)
endfunction

function! vimterminal#DeleteTerminal()
    " let l:currentbuf = expand('<abuf>')
    " current bufnr can be change on BufWipeout, that is true.
    " for that reason we need to use afile which is the file name of
    " the manipulated buffer
    " let l:name = map(getbufinfo(l:currentbuf), 'v:val.name')[0]
    let l:name = expand('<afile>')
    let l:start = stridx(l:name, "!/VIMTERM/")
    if start >= 0 && vimterminal#startswith("!/VIMTERM/", l:name[l:start:])
        let l:path = l:name[l:start + len("!/VIMTERM/"):]
        " echo l:path
        " sleep 2
        " the for loop also deletes all other buf objects in terminal_buffers
        " which are related to the same main_path
        let l:main_path = g:vimterminal_buffers[l:path]['main_path']
        for l:vt_buffer_key in keys(g:vimterminal_buffers)
            let l:vt_buffer = g:vimterminal_buffers[l:vt_buffer_key]
            if l:vt_buffer['main_path'] == l:main_path
                unlet g:vimterminal_buffers[l:vt_buffer_key]
            endif
        endfor
    endif
endfunction

function! vimterminal#CreateTerm(path, cmds)
        execute "enew"
        let l:cmd = "zsh"
        if has_key(a:cmds, a:path)
            let l:cmd = a:cmds[a:path]
        endif
        " the ! is important for nerdtree
        let l:jobid = termopen('trap ctrl_c INT; function ctrl_c() { ' . &shell . ' }; ' . l:cmd['command'], {'term_name': '!/VIMTERM/' . a:path, 'term_finish': 'close', 'norestore': 1, 'hidden': 1, 'cwd': a:path})
        let l:buf = { 'bufnr': bufnr("%"), 'main_path': l:cmd['main_path'] }
        let g:vimterminal_buffers[a:path] = l:buf
        call setbufvar(l:buf['bufnr'], '&buflisted', 0)
        return l:buf
endfunction

function! vimterminal#GetTermBack(path, cmds)
    let l:currentwinnr = winnr()
    let l:currentbufnr = bufnr("%")
    execute "botright split"
    " execute "botright"
    let l:buf = get(g:vimterminal_buffers, a:path)
    let l:already_exists = 1
    if l:buf['bufnr'] == -1
        let l:main_path = l:buf['main_path']
        let l:buf = get(g:vimterminal_buffers, l:buf['main_path'])
        if (has_key(l:buf, 'bufnr') && l:buf['bufnr'] == -1) || !has_key(l:buf, 'bufnr')
            let l:already_exists = -1
            let l:buf = vimterminal#CreateTerm(l:main_path, a:cmds)
            let g:vimterminal_buffers[a:path] = l:buf
        endif
    endif
    execute 'silent resize ' . g:termwinsize
    " echo l:buf
    execute "b"..l:buf['bufnr']
    " the ! is important for nerdtree
    if l:already_exists == -1
        execute "file !/VIMTERM/" . a:path
    endif
    " execute "rightb vspl "..g:vimterminal_buffer
    execute "norm G"
    "execute "<ESC>"
    call win_gotoid(win_getid(l:currentwinnr))
    execute "b"..l:currentbufnr
endfunction

