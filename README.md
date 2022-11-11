# jekyll.vim

The repo is fork from parkr/vim-jekyll with some extend.
It can list and input your categories. It can list and input your tag.
You can follow the list or add a new categorie or tag.
You should write all your categories exited in categories.txt when you 
first use the plugin. One line is one categorie only in categories.txt.

It can auto complete hte file and fold when you use the Jpost with TAB key.

Blogging from the command line should not be tedious.

This script is intended to automate the process of creating and editing
[Jekyll](http://jekyllrb.com/) blog posts from within
[vim](http://www.vim.org/).

This is a complete rewrite of
[csexton/jekyll.vim](https://github.com/csexton/jekyll.vim/) with these
improvements:

* Commands to edit/split/vsplit/tabnew a post and draft.
* Tab completion for opening existing posts and drafts.
* Recognizes Octopress blogs and others with custom `_posts` and `_drafts` directory
* Customizable template for new posts
* Customizable build command, with automatic support for bundler

## Commands

The `:Jpost` (Jekyll post) command is used to create and edit blog posts. It
has variants for opening a post in a horizontal or vertical split or a new
tab. Call with a bang, (eg: `:Jpost!`) to create a new post. Call without a
bang (eg: `:Jpost`) to edit a post. The `:Jbuild` command can be used to build
a blog.

| Commands | Description  |
| -- | -- |
| `:Jpost[!] [{name}]` | Create or edit the specified post. With no argument, you will be prompted to select a post or enter a title.|
| `:JSpost[!] [{name}]` | Same as `:Jpost`, but opens post in a horizontal split.|
| `:JVpost[!] [{name}]` | Same as `:Jpost`, but opens post in a vertical split. |
| `:JTpost[!] [{name}]` | Same as `:Jpost`, but opens post in a tab. |
| `:Jdraft[!]  [{name}]` | Create or edit the specified draft. With no argument, you will be prompted to select a draft or enter a title. |
| `:JSdraft[!] [{name}]` | Same as `:Jdraft`, but opens draft in a horizontal split. |
| `:JVdraft[!] [{name}]` | Same as `:Jdraft`, but opens draft in a vertical split.
| `:JTdraft[!] [{name}]` | Same as `:Jdraft`, but opens draft in a tab. |
| `:Jbuild [{args}]` | Generate blog. This will check for the presence of a Gemfile; if found `bundle exec` is used to run the `jekyll` command. The blog will be built with: `jekyll --no-auto --no-server BLOG_ROOT BLOG_ROOT/SITE_DIR <args>`. If this doesn't fit your situation, you can set a custom command with `g:jekyll_build_command`. When using a custom command no check for a Gemfile is performed. |
| `:Jserve [{args}]`| Serve blog. This will check for the presence of a Gemfile. If found `bundle exec` is used to run the `jekyll` command. The blog will be served with: `jekyll serve -s BLOG_ROOT -d BLOG_ROOT/SITE_DIR <args>`. If this doesn't fit your situation, you can set a custom command with `\|g:jekyll_serve_command\|`. When using a custom command no check for a Gemfile is performed. The server is run inline. Use Ctrl-C to exit and resume editing.

See also `:help jekyll-commands`.

## Configuration

See `:help jekyll-configuration`.

Config this in your vim config file. eg:

```vim
let g:jekyll_post_template =  [
    \ '---',
    \ 'layout: post',
    \ 'title: "JEKYLL_TITLE"',
    \ 'date: "JEKYLL_DATE"',
    \ 'categories: "JEKYLL_CATEGORIES"',
    \ 'tags: "JEKYLL_TAGS"',
    \ '---',
    \ '']
```

## License

Same as Vim itself, see `:help license`.
