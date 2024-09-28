" Title:        Vim Terminal
" Description:  A plugin to provide an example for creating Vim plugins.
" Last Change:  8 November 2021
" Maintainer:   Example User <https://github.com/example-user>

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_vimterminal")
    finish
endif
let g:loaded_vimterminal = 1

" Exposes the plugin's functions for use as commands in Vim.
command! -nargs=0 DisplayTime call vimterminal#DisplayTime()
command! -nargs=0 DefineWord call vimterminal#DefineWord()
command! -nargs=0 AspellCheck call vimterminal#AspellCheck()
command! -nargs=0 GetTerm call vimterminal#GetTerm()
command! -nargs=0 GetTermBack call vimterminal#GetTermBack()
command! -nargs=0 VimtermToggle call vimterminal#ToggleTerm()
command! -nargs=0 CreateTerm call vimterminal#CreateTerminal()
command! -nargs=0 DeleteTerm call vimterminal#DeleteTerminal()

" autocmd!
autocmd BufWipeout * :call vimterminal#DeleteTerminal()


