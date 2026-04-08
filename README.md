# vim-markdown-links-naive

Vim plugin that exposes a single command:

```vim
:MarkdownLinksAsReferences
```

And a `<Plug>` mapping target for keybindings:

```vim
<Plug>(MarkdownLinksAsReferences)
```

The command scans the current buffer and rewrites Markdown links into reference
style links. Reference definitions are written at the bottom of the document in
the order links first appear.

## Installation (vim-plug)

```vim
call plug#begin('~/.vim/plugged')
Plug 'OlegKarasik/vim-markdown-links-naive'
call plug#end()
```

Optional lazy-loading by command:

```vim
call plug#begin('~/.vim/plugged')
Plug 'OlegKarasik/vim-markdown-links-naive', { 'on': 'MarkdownLinksAsReferences' }
call plug#end()
```

Optional keymap:

```vim
nmap <leader>mr <Plug>(MarkdownLinksAsReferences)
```

## Example

Input:

```markdown
first [A](https://a)
second [B](https://b "title")
third [A](https://a)
```

Output:

```markdown
first [A][1]
second [B][2]
third [A][1]

[1]: https://a
[2]: https://b "title"
```
