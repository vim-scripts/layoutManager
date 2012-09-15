" -------------------
" LayoutManager
" -------------------

" Todo: 
" Remove tabs and windows from the containers, at the same time from the editor
" Ajouter une fonction pour aller directement a une fenetre style gt 1 gt 5 pour les tabs mais pour une fenetre

"===========================================
" Global commands
"===========================================

" To quicly jump to a window number
nmap <tab>] :let g:lmWindowNumber = input('goto window number: ') \| exe g:lmWindowNumber . 'wincmd w'<cr>
" To quickly save and restore windows sizes in current tab. Use the s:Tab.ResizeAll() function to restore each layout's default sizes.
let g:lmRestoreSizes = ''
nmap <tab><f11> :let g:lmRestoreSizes = winrestcmd()<cr>
nmap <tab><f12> :exe g:lmRestoreSizes<cr>

"===========================================
" Class lmContainer
"===========================================

    " Define the class as a dictionnary
    let s:lmContainer = {}

    "-------------
    " Constructors
    "-------------

    function! s:lmContainer.New(base) dict
        " Member variables
        let self.base = a:base
        let self.index = 0
        let self.count = 0
        let self.items = []
        " Create the new object
        return deepcopy(self) " Here a deepcopy is needed because it contains an array (self.items), a copy would only copy the reference to the array.
    endfunction

    "------------
    " Properties
    "------------

    " 'Implements IEnumerator-like interface'
    function! s:lmContainer.GetCurrent() dict
        let l:name = self.items[self.index] " Get the key (name) from items using the index
        return self[l:name] " Return the value using the key (name)
    endfunction

    function! s:lmContainer.GetCount() dict
        return self.count
    endfunction

    "------------
    " Methods
    "------------

    " 'Implements IEnumerator-like interface'
    function! s:lmContainer.MoveNext() dict
        if self.index >= self.GetCount() - 1
            return 0
        else
            let self.index = self.index + 1 
            return 1
        endif
    endfunction

    " 'Implements IEnumerator-like interface'
    function! s:lmContainer.Reset() dict
        let self.index = -1
    endfunction

    " Add a new item to the container
    function! s:lmContainer.Add(item) dict
        let a:item.base = self
        let a:item.index = self.count " The item will know which index it is itself located
        let self.count = self.count + 1
        call add(self.items, a:item.name)
        exe "call extend(self, {'".a:item.name."':a:item}, 'force')"
    endfunction

"===========================================
" Class lmLayout
"===========================================

    " Define the class as a dictionnary
    let g:lmLayout = {}

    "-------------
    " Constructors
    "-------------

    function! g:lmLayout.New(name) dict
        " Member variables
        let self.name = a:name 
        " Layout objects contain tabs (Here a capital letter is used for this variable because it is not possible in vim to return a ref through a getter function and do for example echo myLayout1.GetTabs.myTab1.GetName(), so the variable is accessed directly)
        let self.Tabs = s:lmContainer.New(self)
        " Create the new object
        return copy(self)
    endfunction

    "------------
    " Properties
    "------------

    function! g:lmLayout.GetName() dict
        return self.name
    endfunction

"===========================================
" Class lmTab
"===========================================

    " Define the class as a dictionnary
    let g:lmTab = {}

    "-------------
    " Constructors
    "-------------

    function! g:lmTab.New(name, template) dict
        " Create the tab
        tabnew
        " Member variables
        let self.number = tabpagenr()
        let self.index = 0
        let self.name = a:name 
        let self.template = a:template
        " Tab objects contain windows
        let self.Windows = s:lmContainer.New(self)
        " Apply the selected template
        call self.ApplyTemplate()
        return copy(self)
    endfunction

    "------------
    " Properties
    "------------

    function! g:lmTab.GetNumber() dict
        return  self.number
    endfunction

    function! g:lmTab.GetName() dict
        return self.name
    endfunction

    "------------
    " Methods
    "------------

    " Check if current tab is in focus
    function! g:lmTab.IsFocused() dict
        return self.GetNumber() == tabpagenr() " Compare the tab number with the current tab of the editor
    endfunction

    " Set focus on the tab
    function! g:lmTab.SetFocus() dict
        if self.IsFocused() == 0 " If this tab is not focused, set the focus to it
            exe 'normal ' . self.number . 'gt'
        endif
    endfunction

    " Resize all windows in the tab
    function! g:lmTab.ResizeAll() dict
        call self.Windows.Reset()
        while self.Windows.MoveNext()
             let l:window = self.Windows.GetCurrent()
             call l:window.Resize()
        endwhile
    endfunction

    function! g:lmTab.Close() dict
        call self.SetFocus() " base is Windows, base.base is Tab
        tabclose! 
    endfunction

    " Apply the selected template
    function! g:lmTab.ApplyTemplate() dict

        if self.template == 'MyTemplate1'
            " +-----+
            " |1|2|3| menu, code, project
            " |-----|
            " |4|5|6| output2, code2, files
            " |-----|
            " |  7  | output
            " +-----+

            " Create the windows
             split
             split
             2wincmd k
             vsplit
             vsplit
             wincmd j
             vsplit
             vsplit

            " row1
            call self.Windows.Add(s:lmWindow.New('menu', 20, 20))    " 1
            call self.Windows.Add(s:lmWindow.New1('code'))           " 2
            call self.Windows.Add(s:lmWindow.New('project', 20, 20)) " 3
            " row2
            call self.Windows.Add(s:lmWindow.New('output2', 20, 20)) " 4
            call self.Windows.Add(s:lmWindow.New1('code2'))          " 5
            call self.Windows.Add(s:lmWindow.New('files', 20, 20))   " 6
            " row3
            call self.Windows.Add(s:lmWindow.New('output', 8, 2))    " 7

        elseif self.template == 'MyTemplate2'
            " +-----+
            " |  1  | menu
            " |-----|
            " |  2  | code
            " |-----|
            " |  3  | code2
            " |-----|
            " |  4  | output
            " +-----+

            " Create the windows
             split
             wincmd j
             split
             wincmd j
             split
             wincmd j

            " row1
            call self.Windows.Add(s:lmWindow.New('menu', 5, 0))     " 1
            " row2
            call self.Windows.Add(s:lmWindow.New('code', 20, 0))    " 2
            " row3
            call self.Windows.Add(s:lmWindow.New('code2', 20, 0))   " 3
            " row4
            call self.Windows.Add(s:lmWindow.New('output', 9, 0))   " 4

        elseif self.template == 'MyTemplate3'
            " +-----+
            " |1|2|3| menu, code, project
            " |-----|
            " |4|5|6| output2, code2, files
            " |-----|
            " |  7  | output
            " +-----+

            " Create the windows
             split
             split
             2wincmd k
             vsplit
             vsplit
             wincmd j
             vsplit
             vsplit

            " row1
            call self.Windows.Add(s:lmWindow.New('menu', 20, 20))    " 1
            call self.Windows.Add(s:lmWindow.New1('code'))           " 2
            call self.Windows.Add(s:lmWindow.New('project', 20, 20)) " 3
            " row2
            call self.Windows.Add(s:lmWindow.New('output2', 20, 20)) " 4
            call self.Windows.Add(s:lmWindow.New1('code2'))          " 5
            call self.Windows.Add(s:lmWindow.New('files', 20, 20))   " 6
            " row3
            call self.Windows.Add(s:lmWindow.New('output', 8, 2))    " 7

        endif

        " Resize all the windows at once
        call self.ResizeAll()

        " Save the resize command to quickly restore the windows size using the mapping above
        let g:lmRestoreSizes = winrestcmd()

        " Postion the cursor
        call self.Windows.code.SetFocus()
    endfunction

"===========================================
" Class window
"===========================================

    " Define the class as a dictionnary
    let s:lmWindow = {}

    "-------------
    " Constructors
    "-------------

    function! s:lmWindow.New(name, hSize, vSize) dict
        " Member variables
        let self.index = 0
        let self.number = 0
        let self.name = a:name
        let self.hSize = a:hSize
        let self.vSize = a:vSize
        let self.wrap = 0
        " Set window options 
        call self.SetWrap(0)
        " Return a new object of this type
        return copy(self)
    endfunction

    " 'Overload' the constructor
    function! s:lmWindow.New1(name) dict
        return s:lmWindow.New(a:name, 0, 0)
    endfunction

    "------------
    " Properties
    "------------

    function! s:lmWindow.GetNumber() dict
        if self.number == 0 
            let self.number = self.index + 1
        endif
        return self.number
    endfunction

    function! s:lmWindow.GetName() dict
        return self.name
    endfunction

    function! s:lmWindow.SetHSize(value) dict
        self.hSize = a:value
    endfunction

    function! s:lmWindow.SetVSize(value) dict
        self.vSize = a:value
    endfunction

    function! s:lmWindow.GetWrap() dict
        return self.wrap
    endfunction

    function! s:lmWindow.SetWrap(value) dict
        let self.wrap = a:value
        if self.wrap == 0
            set nowrap
        else
            set wrap
        endif
    endfunction

    "------------
    " Methods
    "------------

    " Check if current window is in focus
    function! s:lmWindow.IsFocused() dict
        return self.GetNumber() == winnr() " Compare the window number with the current window of the editor
    endfunction

    " Set focus on the window
    function! s:lmWindow.SetFocus() dict
        if self.base.base.IsFocused() == 0 " Check if the tab where this window is contained is the focused tab, if it is not, set the focus to the tab
            call self.base.base.SetFocus()
        endif
        if self.IsFocused() == 0 " If this window is not the focused window, set the focus to it
            exe self.GetNumber() . "wincmd w" 
        endif
    endfunction

    " Resize the specified window
    function! s:lmWindow.Resize() dict
        call self.base.base.SetFocus() " base is Windows, base.base is Tab
        call self.SetFocus()
        if self.hSize > 0
            exe self.GetNumber() .'resize ' . self.hSize
        endif
        if self.vSize > 0
            exe 'vert ' . self.GetNumber() . 'resize ' . self.vSize
        endif
    endfunction

    " Create empty content in the current window
    function! s:lmWindow.Empty() dict
        call self.base.base.SetFocus() " base is Windows, base.base is Tab
        call self.SetFocus()
        enew!
    endfunction

    " Write text in the window
    function! s:lmWindow.Write(text, mode) dict
        call self.base.base.SetFocus() " base is Windows, base.base is Tab
        call self.SetFocus()
        " Insert at beginning of the window
        if a:mode == 0
            call append(0, [a:text])
        " Append at the end of the window
        elseif a:mode == 1
            call append('$', [a:text])
        " Insert at current position in the window
        elseif a:mode == 2
            call append('.', [a:text])
        " Overwrite text of the current window by the new text
        elseif a:mode == 3
            call self.Empty()
            call append(0, [a:text])
        endif
    endfunction

    " Execute a command in the window
    function! s:lmWindow.Execute(command) dict
        call self.base.base.SetFocus() " base is Windows, base.base is Tab
        call self.SetFocus()
        call self.Empty()
        exe a:command
    endfunction

    " Execute a shell command in the window
    function! s:lmWindow.ExecuteShell(command) dict
        call self.Execute('r! ' . a:command)
    endfunction

    " Open a file in the window
    function! s:lmWindow.OpenFile(fileName) dict
        call self.Execute('e! ' . a:fileName)
    endfunction

"===========================================
" Tests
"===========================================

" ajouter un mapping pour resizer avec ResizeAll ou avec le winrestcmd() a ajouter?
" ensuite faire un project file avec un layout, ajouter le project file dans le layout
" faire une doc simple

" Create a new layout
"let myLayout1 = g:lmLayout.New('MyLayout1')

" Add tabs to the layout
"call myLayout1.Tabs.Add(g:lmTab.New('MyTab1', 'MyTemplate1'))
"call myLayout1.Tabs.Add(g:lmTab.New('MyTab2', 'MyTemplate2'))

" Send commands to some of the windows of MyTab1
"call myLayout1.Tabs.MyTab1.Windows.code.Execute('e ' . $VIM . '/vimrc') " Show the vimrc file in the code window
"call myLayout1.Tabs.MyTab1.Windows.output.Write("this is the output window 1!", 3) " Write text in the output window
"call myLayout1.Tabs.MyTab1.Windows.files.ExecuteShell('dir c:\') " List a directory in the files window
"call myLayout1.Tabs.MyTab1.Windows.code.SetFocus()

" Send commands to some of the windows of MyTab2
"call myLayout1.Tabs.MyTab2.Windows.menu.Write("this is the menu!", 3) " Write text in the menu window
"call myLayout1.Tabs.MyTab2.Windows.code2.Execute('e ' . $VIM . '/vimrc') " Show the vimrc file in the code2 window

"let myLayout2 = s:layout.New('MyLayout2')
" Set focus to MyTab1
"call myLayout1.Tabs.MyTab1.SetFocus()
