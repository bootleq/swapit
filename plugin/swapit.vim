"SwapIt: General Purpose related word swapping for vim
" Script Info and Documentation  {{{1
"=============================================================================
"
"    Copyright: Copyright (C) 2008 Michael Brown {{{2
"      License: The MIT License
"
"               Permission is hereby granted, free of charge, to any person obtaining
"               a copy of this software and associated documentation files
"               (the "Software"), to deal in the Software without restriction,
"               including without limitation the rights to use, copy, modify,
"               merge, publish, distribute, sublicense, and/or sell copies of the
"               Software, and to permit persons to whom the Software is furnished
"               to do so, subject to the following conditions:
"
"               The above copyright notice and this permission notice shall be included
"               in all copies or substantial portions of the Software.
"
"               THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"               OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"               MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"               IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"               CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"               TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"               SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"
" Name Of File: swapit.vim {{{2
"  Description: system for swapping related words
"   Maintainer: Michael Brown
" Contributors: Ingo Karkat (speedating compatability)
"  Last Change:
"          URL:
"      Version: 0.1.2
"
"        Usage: {{{2
"
"               On a current word that is a member of a swap list use the
"               incrementor/decrementor keys (:he ctrl-a,ctrl-x). The script
"               will cycle through a list of related options.
"
"               eg. 1. Boolean
"
"               foo=yes
"
"               in normal mode, pressing ctrl-a on the y will make it.
"
"               foo=no
"
"               The plugin handles clashes. Eg. if yes appears in more than
"               one swap list (eg. yes/no or yes/no/maybe), a confirm dialog will appear.
"
"               eg. 2. Multi Word Swaps.
"
"               Hello World! is a test multi word swap.
"
"               on 'Hello World!' go select in visual (vi'<ctrl-a>) to get
"
"               'GoodBye Cruel World!'
"
"               eg 3. Defining custom swaps
"
"               A custom list is defined as follows.
"
"               :SwapList datatype bool char int float double
"
"               The first argument is the list name and following args
"               are members of the list.
"
"               if there is no match then the regular incrementor decrementor
"               function will work on numbers
"
"               At the bottom of the script I've added some generic stuff but
"
"               You can create a custom swap file for file types at
"
"               ~/.vim/after/ftplugins/<filetype>_swapit.vim
"               with custom execs eg.
"               exec "SwapList function_scope private protected public"
"
"               For this alpha version multi word swap list is a bit trickier
"               to to define. You can add to the swap list directly using .
"
"                 call add(g:swap_lists, {'name':'Multi Word Example',
"                             \'options': ['swap with spaces',
"                             \'swap with  @#$@# chars in it' , \
"                             \'running out of ideas here...']})
"
"               Future versions will make this cleaner
"
"               Also if you have a spur of the moment Idea type
"               :SwapIdea
"               To get to the current filetypes swapit file
"
"               4. Insert mode completion
"
"               You can use a swap list in insert mode by typing the list name
"               and hitting ctrl+b eg.
"
"               datatype<ctrl+b>    once  will provide a complete list of datatypes.
"
"               (Note: insert mode complete is still buggy and will eat your current
"               word if you keep hitting ctrl+b on an incorrect. It's disabled
"               by default so as not to annoy anyone.  Uncomment the line in the
"               command configuration if you want to try it out.
"
"               Note: This alpha version doesnt create the directory structure
"
"               To integrate with other incrementor scripts (such as
"               speeddating.vim or monday.vim), :nmap
"               <Plug>SwapItFallbackIncrement and <Plug>SwapItFallbackDecrement
"               to the keys that should be invoked when swapit doesn't have a
"               proper option. For example for speeddating.vim:
"
"               nmap <Plug>SwapItFallbackIncrement <Plug>SpeedDatingUp
"               nmap <Plug>SwapItFallbackDecrement <Plug>SpeedDatingDown
"
"         Bugs: {{{2
"
"               Will only give swap options for first match (eg make sure
"               options are unique).
"
"               The visual mode is inconsistent on highlighting the end of a
"               phrase occasionally one character under see VISHACK
"
"               Visual selection bug: if you have set selection=exclusive. You
"               might have trouble with the last character not being selected
"               on a multi word swap
"
"        To Do: {{{2
"
"               - improve filetype handling
"               - look at load performance if it becomes an issue
"               - might create a text file swap list rather than vim list
"               - look at clever case option to reduce permutations
"               - look at possibilities beyond <cword> for non word swaps
"                   eg swap > for < , == to != etc.
"               - add a repeated keyword warning for :SwapList
"               - add repeat resolition confirm option eg.
"                SwapSelect>   a. (yes/no) b. (yes/no/maybe)
"
"               ideas welcome at mjbrownie (at) gmail dot com.
"
"               I'd like to compile some useful swap lists for different
"               languages to package with the script
"
"Variable Initialization {{{1
"if exists('g:loaded_swapit')
"    finish
"elseif v:version < 700
"    echomsg "SwapIt plugin requires Vim version 7 or later"
"    finish
"endif
let g:loaded_swapit = 1
let g:swap_xml_matchit = []

if !exists('g:swap_lists')
    let g:swap_lists = []
endif
if !exists('g:swap_list_dont_append')
    let g:swap_list_dont_append = 'no'
endif
" TODO: doc this option
if !exists('g:swapit_max_conflict')
    let g:swapit_max_conflict = 7
endif
if empty(maparg('<Plug>SwapItFallbackIncrement', 'n'))
    nnoremap <Plug>SwapItFallbackIncrement <c-a>
endif
if empty(maparg('<Plug>SwapItFallbackDecrement', 'n'))
    nnoremap <Plug>SwapItFallbackDecrement <c-x>
endif

"Command/AutoCommand Configuration {{{1
"
" For executing the listing
nnoremap <silent><c-a> :<c-u>call SwapIt('w', 0, v:count1)<cr>
nnoremap <silent><c-x> :<c-u>call SwapIt('w', 1, v:count1)<cr>
vnoremap <silent><c-a> :<c-u>call SwapIt('v', 0, v:count1)<cr>
vnoremap <silent><c-x> :<c-u>call SwapIt('v', 1, v:count1)<cr>
"inoremap <silent><c-b> <esc>b"sdwi <c-r>=SwapInsert()<cr>
"inoremap <expr> <c-b> SwapInsert()

" For adding lists
com! -nargs=* SwapList call AddSwapList(<q-args>)
com! ClearSwapList let g:swap_lists = []
com! SwapIdea call OpenSwapFileType()
" com! -range -nargs=1 SwapWordVisual call SwapIt('v', <f-args>, v:count1)
"au BufEnter call LoadFileTypeSwapList()
com! SwapListLoadFT call LoadFileTypeSwapList()
com! -nargs=+ SwapXmlMatchit call AddSwapXmlMatchit(<q-args>)
"Swap Processing Functions {{{1
"
"
"SwapIt() {{{2
fun! SwapIt(text_class, backward, count)
    let s:backward = a:backward
    let s:text_class = a:text_class
    let ctext = s:ctext(s:text_class)

    if ctext["col"] == 0
        call s:fallback(s:backward, a:count)
    endif

    let comfunc_result = 0
    "{{{3 css omnicomplete property swapping
    if exists('b:swap_completefunc')
        exec "let complete_func = " . b:swap_completefunc . "(". a:backward .")"
        if comfunc_result
            return 1
        endif
    endif

    if g:swap_list_dont_append == 'yes'
        let test_lists =  g:swap_lists
    else
        let test_lists =  g:swap_lists + g:default_swap_list
    endif

    let match_list = []

    " Main for loop over each swaplist {{{3
    for swap_list  in test_lists
        let word_options = swap_list['options']
        let word_index = index(word_options, ctext["text"])

        if word_index != -1
            call add(match_list, swap_list)
        endif
    endfor
    "}}}

    if len(match_list) > 1
        let choice = s:confirm_choices(match_list, ctext)
        if choice
            call s:cycle(match_list[choice - 1], ctext, a:count)
        else
            echohl WarningMsg | echo "Aborted." | echohl None
        endif
    elseif len(match_list) == 1
        let swap_list = match_list[0]
        call s:cycle(swap_list, ctext, a:count)
    else
        call s:fallback(a:backward, a:count)
    endif
endfun
" s:cycle()  cycle options in list {{{2
fun! s:cycle(swap_list, ctext, count)
    let candidates = a:swap_list["options"]
    let new_index = index(candidates, a:ctext["text"]) + (s:backward ? -1 : 1) * a:count
    let new_index = new_index % len(candidates)
    let new_word = a:swap_list["options"][new_index]

    "XML matchit handling  {{{3
    if index(g:swap_xml_matchit, a:swap_list['name']) != -1
        " TODO: maybe use searchpair() instead of matchit
        " TODO: use substitute() instead of ciw
        " TODO: don't change 'a' mark
        if match(getline("."),"<\\(\\/". a:ctext["text"] ."\\|". a:ctext["text"] ."\\)[^>]*>" ) == -1
            return 0
        endif
        execute "normal T<ma%"
        execute "normal l\"_ciw\<C-R>=new_word\<CR>`aciw\<C-R>=new_word\<CR>"
    " Regular swaps {{{3
    else
        call setline('.',
                    \    substitute(
                    \        getline('.'),
                    \        '\%' . a:ctext["col"] . 'c' . escape(a:ctext["text"], '~\[^$'),
                    \        escape(new_word, '~\&'),
                    \        ''
                    \    )
                    \ )

        if new_word =~ '\W'
            call cursor(line('.'), a:ctext["col"])
            normal v
            call cursor(line('.'), a:ctext["col"] + strlen(new_word) - 1)
        endif
    endif
    " 3}}}
endfun
"
"s:confirm_choices() {{{2
fun! s:confirm_choices(match_list, ctext)
    let index = 0
    let candidates = []
    let choices = []

    if len(a:match_list) >= g:swapit_max_conflict
        redraw
        echohl WarningMsg | echomsg "Swapit: Too many matches for: '" . a:ctext["text"] . "'" | echohl None
        return
    endif

    for list in a:match_list

        let mark = nr2char(char2nr('A') + index)
        call add(candidates, join([
                    \     ' ' . mark,
                    \     ') ',
                    \     list['name'],
                    \     " => ",
                    \     list['options'][(index(list['options'], a:ctext["text"]) + 1) % len(list['options'])],
                    \ ], ''))
        call add(choices, '&' . mark)
        let index += 1
    endfor

    return confirm("SwapIt with:\n" . join(candidates, "\n"), join(choices, "\n"), 0)
endfun

fun! s:fallback(backward, count)
    " TODO: is this works for visual mode?
    if s:backward
        execute "normal " . a:count . "\<Plug>SwapItFallbackDecrement"
    else
        execute "normal " . a:count . "\<Plug>SwapItFallbackIncrement"
    endif
endfun
"Cursor, line, register utils {{{1
"
fun! s:ctext(text_class)
    if a:text_class == 'w'
        let s:ctext = s:cword()
    elseif a:text_class == 'v'
        let s:ctext = s:cvisual()
    else
        let s:ctext = {
                    \     "text": '',
                    \     "col": 0,
                    \ }
    endif
    return s:ctext
endfunction
" s:cword:
" - must contain the character under cursor.
" - has text and col (start column) attributes.
fun! s:cword()
    let cword = expand('<cword>')
    let cchar = s:cchar()
    let cpos = s:cpos()
    let s:cword = {
                \     "text": '',
                \     "col": 0,
                \ }

    if match(cword, cchar) >= 0
        let s:cword["col"] = match(
                    \     getline('.'),
                    \      '\%>' . max([0, cpos["col"] - strlen(cword) - 1]) . 'c' . cword,
                    \     0,
                    \     0
                    \ ) + 1
        let s:cword["text"] = cword
    endif
    return s:cword
endfun

fun! s:cvisual()
    let save_mode = mode()

    call s:save_reg('a')
    normal gv"ay
    let s:cvisual = {
                \     "text": @a,
                \     "col": getpos('v')[2],
                \ }

    if save_mode == 'v'
        normal gv
    endif
    call s:restore_reg('a')

    return s:cvisual
endfun

fun! s:cchar()
    call s:save_reg('a')
    normal yl
    let cchar = @a
    call s:restore_reg('a')
    return cchar
endfun

fun! s:cpos()
    let pos = getpos('.') 
    let s:cpos = {
                \   "line": pos[1],
                \   "col": pos[2],
                \ }
    return s:cpos
endfun

fun! s:save_reg(name)
    let s:save_reg = [getreg(a:name), getregtype(a:name)]
endfun

fun! s:restore_reg(name)
    if exists('s:save_reg')
        call setreg(a:name, s:save_reg[0], s:save_reg[1])
    endif
endfun
"Insert Mode List Handling {{{1
"
"SwapInsert() call a swap list from insert mode
fun! SwapInsert()
    for swap_list  in (g:swap_lists + g:default_swap_list)
        if swap_list['name'] == @s
            call complete(col('.'), swap_list['options'])
            return ''
        endif
    endfor
    return  ''
endfun
"List Maintenance Functions {{{1
"AddSwapList()  Main Definition Function {{{2
"use with after/ftplugin/ vim files to set up file type swap lists
fun! AddSwapList(s_list)

    let word_list = split(a:s_list,'\s\+')

    if len(word_list) < 3
        echo "Usage :SwapList <list_name> <member1> <member2> .. <membern>"
        return 1
    endif

    let list_name = remove (word_list,0)

    call add(g:swap_lists,{'name':list_name, 'options':word_list})
endfun

fun! AddSwapXmlMatchit(s_list)
    let g:swap_xml_matchit = split(a:s_list,'\s\+')
endfun
"LoadFileTypeSwapList() "{{{2
"sources .vim/after/ftplugins/<file_type>_swapit.vim
fun! LoadFileTypeSwapList()

    "Initializing  the list {{{3
"    call ClearSwapList()
    let g:swap_lists = []
    let g:swap_list = []
    let g:swap_xml_matchit = []

    let ftpath = "~/.vim/after/ftplugin/". &filetype ."_swapit.vim"
    let g:swap_lists = []
    if filereadable(ftpath)
        exec "source " . ftpath
    endif

endfun

"OpenSwapFileType() Quick Access to filtype file {{{2
fun! OpenSwapFileType()
    let ftpath = "~/.vim/after/ftplugin/". &filetype ."_swapit.vim"
    if !filereadable(ftpath)
        "TODO add a directory check
        exec "10 split " . ftpath
        "exec 'norm! I "SwapIt.vim definitions for ' . &filetype . ': eg exec "SwapList names Tom Dick Harry\"'
        return ''
    else
        exec "10 split " . ftpath
    endif
    exec "norm! G"
endfun
"Default DataSet. Add Generic swap lists here {{{1
if g:swap_list_dont_append == 'yes'
    let g:default_swap_list = []
elseif ! exists('g:default_swap_list')
    " TODO: use single interface to append lists
    let g:default_swap_list = [
                \{'name':'yes/no', 'options': ['yes','no']},
                \{'name':'Yes/No', 'options': ['Yes','No']},
                \{'name':'True/False', 'options': ['True','False']},
                \{'name':'true/false', 'options': ['true','false']},
                \{'name':'AND/OR', 'options': ['AND','OR']},
                \{'name':'Hello World', 'options': ['Hello World!','GoodBye Cruel World!' , 'See You Next Tuesday!']},
                \{'name':'On/Off', 'options': ['On','Off']},
                \{'name':'on/off', 'options': ['on','off']},
                \{'name':'ON/OFF', 'options': ['ON','OFF']},
                \{'name':'comparison_operator', 'options': ['<','<=','==', '>=', '>' , '=~', '!=']},
                \{'name': 'datatype', 'options': ['bool', 'char','int','unsigned int', 'float','long', 'double']},
                \{'name':'weekday', 'options': ['Sunday','Monday', 'Tuesday', 'Wednesday','Thursday', 'Friday', 'Saturday']},
                \]
endif
"NOTE: comparison_operator doesn't work yet but there in the hope of future
"
"capability

" modeline: {{{
" vim: expandtab softtabstop=4 shiftwidth=4 foldmethod=marker
