" jekyll.vim
" Author:  Joshua Priddle <jpriddle@me.com>
" URL:     https://github.com/itspriddle/vim-jekyll
" Version: 0.1.0
" License: Same as Vim itself (see :help license)

if exists('g:loaded_jekyll') || &cp || v:version < 700
  finish
endif
let g:loaded_jekyll = 1

" Configuration {{{

" Directories to search for posts. _source/_posts is for Octopress.
if ! exists('g:jekyll_post_dirs')
  let g:jekyll_post_dirs = ['_posts', '_source/_posts']
endif

" Directories to search for drafts. _source/_drafts is for Octopress.
if ! exists('g:jekyll_draft_dirs')
  let g:jekyll_draft_dirs = ['_drafts', '_source/_drafts']
endif

" Extension used when creating new posts/drafts
if ! exists('g:jekyll_post_extension')
  let g:jekyll_post_extension = '.md'
endif

" Filetype applied to new posts/drafts
if ! exists('g:jekyll_post_filetype')
  let g:jekyll_post_filetype = 'liquid'
endif

" Template for new posts/drafts
if ! exists('g:jekyll_post_template')
  let g:jekyll_post_template = [
    \ '---',
    \ 'layout: post',
    \ 'title: "JEKYLL_TITLE"',
    \ 'date: "JEKYLL_DATE"',
    \ 'categoies: "JEKYLL_CATEGORIES"',
    \ 'tags: "JEKYLL_TAGS"',
    \ '---',
    \ '']
endif

" Directory to place generated files in, relative to b:jekyll_root_dir.
" Usually _site
if ! exists('g:jekyll_site_dir')
  let g:jekyll_site_dir = '_site'
endif

" }}}

" Utility functions {{{

" Print an error message
function! s:error(string)
  echohl ErrorMsg
  echomsg "Error: ".a:string
  echohl None
  let v:errmsg = a:string
endfunction

" Substitute first occurrences of pattern in string with replacement
function! s:sub(string, pattern, replacement)
  return substitute(a:string, '\v\C'.a:pattern, a:replacement, '')
endfunction

" Substitute all occurrences of pattern in string with replacement
function! s:gsub(string, pattern, replacement)
  return substitute(a:string, '\v\C'.a:pattern, a:replacement, 'g')
endfunction

" Returns true if string stars with prefix
function! s:startswith(string, prefix)
  return strpart(a:string, 0, strlen(a:prefix)) ==# a:prefix
endfunction

" Format a file path
function! s:escape_path(path)
  let path = a:path
  let path = s:gsub(path, '/+', '/')
  let path = s:gsub(path, '[\\/]$', '')
  return path
endfunction

" Returns a lower-case string, all non-alpha numeric characters are replaced
" with dashes
function! s:dasherize(string)
  let string = tolower(a:string)
  let string = s:gsub(string, '([^a-z0-9])+', '-')
  let string = s:gsub(string, '(^-*|-*$)', '')
  return string
endfunction

function! s:yaml_formatted_date()
  return strftime("%Y-%m-%d %H:%M:%S")
endfunction

" }}}

" Post functions {{{

" Returns the filename for a new post based on it's title.
function! s:post_filename(title, dir)
  return b:jekyll_post_dir.'/'.a:dir.'/'.strftime('%Y-%m-%d-').s:dasherize(a:title).g:jekyll_post_extension
endfunction
"
" Strips whitespace and escapes double quotes
function! s:post_title(title)
  let title = s:gsub(a:title, '(^[ ]*|[ ]*$)', '')
  let title = s:gsub(title, '[ ]{2,}', ' ')
  let title = s:gsub(title, '"', '\\&')
  return title
endfunction

function! s:post_categories(categories)
  let title = s:gsub(a:categories, '(^[ ]*|[ ]*$)', '')
  let title = s:gsub(title, '[ ]{2,}', ' ')
  let title = s:gsub(title, '"', '\\&')
  return title
endfunction

function! s:post_tags(tags)
  let title = s:gsub(a:tags, '(^[ ]*|[ ]*$)', '')
  let title = s:gsub(title, '[ ]{2,}', ' ')
  let title = s:gsub(title, '"', '\\&')
  return title
endfunction

" Used to autocomplete posts
function! s:post_list(A, L, P)
  let prefix   = b:jekyll_post_dir.'/'
  let data     = s:gsub(glob(prefix.'*.*')."\n".glob(prefix.'*/*')."\n", prefix, '')
  let data     = s:gsub(data, '\'.g:jekyll_post_extension."\n", "\n")
  let data     = s:gsub(data, '\d\d\d\d-\d\d-\d\d-', '')
  let files    = reverse(split(data, "\n"))
  " select the completion candidates using a substring match on the first argument
  " instead of a prefix match (I consider this to be more user friendly)
  let filtered = filter(copy(files), 'v:val =~ a:A')

  if ! empty(filtered)
    return filtered
  endif
endfunction


function! s:post_categories_list()
  let filename = b:jekyll_post_dir.'/'.'categories.txt'
  let lines = readfile(filename)
  let lines = uniq(sort(lines))
  if ! empty(lines)
    let oneLine = join(lines, ", ")
    return oneLine
  endif

  return ""
endfunction

function! s:add_categories(categories)
  let oldClass = s:post_categories_list()
  let oldList = []
  if oldClass != ""
    let oldList = split(oldClass, ", ")
  endif

  let newList = add(oldList, a:categories)
  let newList = uniq(sort(newList))

  if !empty(newList)
    let filename = b:jekyll_post_dir.'/'.'categories.txt'
    call writefile(newList, filename)
  endif
endfunction

" Used to autocomplete posts
function! s:post_dir_list()
  let prefix   = b:jekyll_post_dir.'/'
  let dirs = split(glob(prefix.'*'), "\n")
  let data = []
  for f in dirs
    if isdirectory(f)
      let data = add(data, f)
    endif
  endfor

  let dirStr = join(data, "\n")

  let dirs  = s:gsub(dirStr."\n", prefix, '')
  let dirs  = s:gsub(dirs, '\'.g:jekyll_post_extension."\n", "\n")

  let dirs = reverse(split(dirs, "\n"))
  " select the completion candidates using a substring match on the first argument
  " instead of a prefix match (I consider this to be more user friendly)

  if ! empty(dirs)
    return "\n".join(dirs, ", ")."\n"
  endif
endfunction

" Send the given filename to the editor using cmd
function! s:load_post(cmd, filename)
  let cmd  = empty(a:cmd) ? 'E' : a:cmd
  let cmds = {'E': 'edit', 'S': 'split', 'V': 'vsplit', 'T': 'tabnew'}

  if ! has_key(cmds, cmd)
    return s:error('Invalid command: '. cmd)
  else
    execute cmds[cmd]." ".a:filename
  endif
endfunction

" Create a new blog post
function! s:create_post(cmd, ...)
  let fileName = a:0 && ! empty(a:1) ? a:1 : input('Post file name: ')
  if empty(fileName)
    return s:error('You must specify a file name')
  endif

  let title = a:0 && ! empty(a:1) ? a:1 : input('Post title: ')
  if empty(title)
    return s:error('You must specify a title')
  endif

  let tagCategories = "\n".s:post_categories_list()."\n"
  let categories = a:0 && ! empty(a:1) ? a:1 : input('Post categoies(split by comma. you can select existed or new): who is existed as follow:'.tagCategories.'pleas input categories: ')
  if empty(categories)
    return s:error('You must specify a categoies')
  endif
  call s:add_categories(categories)

  let tagTmps = s:post_dir_list()
  let tags = a:0 && ! empty(a:1) ? a:1 : input('Post tags(split by comma. you can select existed or new. who is existed as follow:'.tagTmps.'please input tag: ')
  let dirs = split(tags, ",")
  let firstDir = dirs[0]
  if empty(tags)
    return s:error('You must specify a tags(same as the dir)')
  endif

  let mdFile = s:post_filename(fileName, firstDir)
  if filereadable(mdFile)
    return s:error(fileName.' already exists!')
  endif

  call s:load_post(a:cmd, mdFile)

  let error = append(0, g:jekyll_post_template)

  if error > 0
    return s:error("Couldn't create post.")
  else
    let &ft = g:jekyll_post_filetype

    silent! %s/JEKYLL_TITLE/\=s:post_title(title)/g
    silent! %s/JEKYLL_DATE/\=s:yaml_formatted_date()/g
    silent! %s/JEKYLL_CATEGORIES/\=s:post_categories(categories)/g
    silent! %s/JEKYLL_TAGS/\=s:post_tags(tags)/g
  endif
endfunction

" Edit a post
function! s:edit_post(cmd, post)
  let prefix   = b:jekyll_post_dir.'/'
  let data     = s:gsub(glob(prefix.'*.*')."\n", prefix, '')
  let data     = s:gsub(data, '\'.g:jekyll_post_extension."\n", "\n")
  let files    = split(data, "\n")
  let data     = s:gsub(data, '\d\d\d\d-\d\d-\d\d-', '')
  let files_   = split(data, "\n")
  let idx      = index(files_, a:post)
  let file = b:jekyll_post_dir.'/'.files[idx].g:jekyll_post_extension

  if filereadable(file)
    return s:load_post(a:cmd, file)
  else
    return s:error('File '.file.' does not exist! Try :J'.a:cmd.'post! to create a new post.')
  endif
endfunction

" Create/edit a post, used by :Jpost and friends to determine if we're editing
" or creating a post.
function! s:open_post(create, cmd, ...)
  if a:create
    return s:create_post(a:cmd, a:1)
  else
    return s:edit_post(a:cmd, a:1)
  endif
endfunction

" Return the command used to build the blog.
function! s:jekyll_bin(subcmd)
  let bin = 'jekyll '.a:subcmd.' '

  if filereadable(b:jekyll_root_dir.'/Gemfile')
    let bin = 'bundle exec '.bin
  endif

  let bin .= ' -s '.b:jekyll_root_dir.' -d '.b:jekyll_root_dir.'/'.g:jekyll_site_dir
  return bin
endfunction

" Return 'jekyll' or 'bundle exec jekyll'
function! s:jekyll_build(cmd)
  if exists('g:jekyll_build_command') && ! empty(g:jekyll_build_command)
    let bin = g:jekyll_build_command
  else
    let bin = s:jekyll_bin('build')
  endif

  echo 'Building, this may take a moment'
  let lines = system(bin.' '.a:cmd)

  if v:shell_error != 0
    return s:error('Build failed')
  else
    echo 'Site built!'
  endif
endfunction

" Return 'jekyll' or 'bundle exec jekyll'
function! s:jekyll_serve(cmd)
  if exists('g:jekyll_serve_command') && ! empty(g:jekyll_serve_command)
    let bin = g:jekyll_serve_command
  else
    let bin = s:jekyll_bin('serve')
  endif

  echo 'Serving at http://localhost:4000 ...'
  let lines = system(bin.' -P 4000 '.a:cmd)

  if v:shell_error != 0
    return s:error('Build failed')
  else
    echo 'Site built!'
  endif
endfunction

" Register a new user command
function! s:define_command(cmd)
  exe 'command! -buffer '.a:cmd
endfunction

" }}}

" Drafts functions {{{

" Returns the filename for a new draft based on it's title.
function! s:draft_filename(title)
  return b:jekyll_draft_dir.'/'.s:dasherize(a:title).g:jekyll_post_extension
endfunction

" Used to autocomplete drafts
function! s:draft_list(A, L, P)
  let prefix   = b:jekyll_draft_dir.'/'
  let data     = s:gsub(glob(prefix.'*.*')."\n", prefix, '')
  let data     = s:gsub(data, '\'.g:jekyll_post_extension."\n", "\n")
  let files    = reverse(split(data, "\n"))
  " select the completion candidates using a substring match on the first argument
  " instead of a prefix match (I consider this to be more user friendly)
  let filtered = filter(copy(files), 'v:val =~ a:A')

  if ! empty(filtered)
    return filtered
  endif
endfunction

" Create a new draft
function! s:create_draft(cmd, ...)
  let title = a:0 && ! empty(a:1) ? a:1 : input('Draft title: ')

  if empty(title)
    return s:error('You must specify a title')
  elseif filereadable(b:jekyll_draft_dir.'/'.title.g:jekyll_post_extension)
    return s:error(title.' already exists!')
  endif

  call s:load_post(a:cmd, s:draft_filename(title))

  let error = append(0, g:jekyll_post_template)

  if error > 0
    return s:error("Couldn't create draft.")
  else
    let &ft = g:jekyll_post_filetype

    silent! %s/JEKYLL_TITLE/\=s:post_title(title)/g
    silent! %s/JEKYLL_DATE/\=s:yaml_formatted_date()/g
  endif
endfunction

" Edit a draft
function! s:edit_draft(cmd, draft)
  let file = b:jekyll_draft_dir.'/'.a:draft.g:jekyll_post_extension

  if filereadable(file)
    return s:load_post(a:cmd, file)
  else
    return s:error('File '.file.' does not exist! Try :J'.a:cmd.'draft! to create a new draft.')
  endif
endfunction

" Create/edit a draft, used by :Jdraft and friends to determine if we're editing
" or creating a draft.
function! s:open_draft(create, cmd, ...)
  if a:create
    return s:create_draft(a:cmd, a:1)
  else
    return s:edit_draft(a:cmd, a:1)
  endif
endfunction

" Publish a draft
function! s:publish_draft(draft)
  let draft_filename = b:jekyll_draft_dir.'/'.a:draft.g:jekyll_post_extension

  if filereadable(draft_filename)
    let post_filename = s:post_filename(a:draft)
    " Check if exists a post with same filename, first
    let success = rename(draft_filename, post_filename)
    if success != 0
      return s:error('Could not rename the file '.file.'! Try :JPublishDraft! to replace the post.')
    endif
    echo 'Draft published on '.post_filename
  else
    return s:error('File '.file.' does not exist! Try :Jdraft! to create a new draft.')
  endif
endfunction

" }}}

" Initialization {{{

" Register plugin commands
"
" :Jpost[!]  - edit in current buffer
" :JSpost[!] - edit in a split
" :JVpost[!] - edit in a vertical split
" :JTpost[!] - edit in a new tab
function! s:register_commands()
  for cmd in ['', 'S', 'V', 'T']
    call s:define_command('-bang -nargs=? -complete=customlist,s:post_list J'.cmd.'post :call s:open_post(<bang>0, "'.cmd.'", <q-args>)')
    call s:define_command('-bang -nargs=? -complete=customlist,s:draft_list J'.cmd.'draft :call s:open_draft(<bang>0, "'.cmd.'", <q-args>)')
  endfor

  call s:define_command('-bang -nargs=? -complete=customlist,s:post_list Ed :call s:open_post(<bang>0, "V", <q-args>)')
  call s:define_command('-nargs=* Jbuild call s:jekyll_build("<args>")')
  call s:define_command('-nargs=* Jserve call s:jekyll_serve("<args>")')
  call s:define_command('-nargs=1 -complete=customlist,s:draft_list JPublishDraft :call s:publish_draft(<q-args>)')
endfunction

" Try to locate the _posts directory
function! s:find_jekyll(path) abort
  let cur_path = a:path
  let old_path = ""
  while old_path != cur_path
    for dir in g:jekyll_post_dirs
      let dir      = s:escape_path(dir)
      if isdirectory(cur_path.'/'.dir)
        return [cur_path, cur_path.'/'.dir]
      endif
    endfor
    let old_path = cur_path
    let cur_path = fnamemodify(old_path, ':h')
  endwhile
  return ['', '']
endfunction

" Try to locate the _drafts directory
function! s:find_jekyll_drafs(path) abort
  let cur_path = a:path
  let old_path = ""
  while old_path != cur_path
    for dir in g:jekyll_draft_dirs
      let dir = s:escape_path(dir)
      if isdirectory(cur_path.'/'.dir)
        return cur_path.'/'.dir
      endif
    endfor
    let old_path = cur_path
    let cur_path = fnamemodify(old_path, ':h')
  endwhile
  return ''
endfunction

" Initialize the plugin if we can detect a Jekyll blog
function! s:init(path)
  let [root_dir, post_dir] = s:find_jekyll(a:path)

  if empty(post_dir) || empty(root_dir)
    return
  endif

  let b:jekyll_root_dir = root_dir
  let b:jekyll_post_dir = post_dir
  let b:jekyll_draft_dir = s:find_jekyll_drafs(a:path)

  silent doautocmd User Jekyll
endfunction

augroup jekyll_commands
  autocmd!
  autocmd User Jekyll call s:register_commands()
augroup END

augroup jekyll_init
  autocmd!
  autocmd BufNewFile,BufReadPost * call s:init(expand('<amatch>:p'))
  autocmd FileType           netrw call s:init(expand('<afile>:p'))
  autocmd VimEnter *
    \ if expand('<amatch>') == '' |
    \   call s:init(getcwd()) |
    \ endif
augroup END

" }}}

" vim:ft=vim:fdm=marker:ts=2:sw=2:sts=2:et
