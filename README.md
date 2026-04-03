# vim-markdown-links-naive

Vim plugin that exposes a single command:

```vim
:MarkdownLinksAsReferences
```

The command scans the current buffer and rewrites Markdown links into reference
style links. Reference definitions are written at the bottom of the document in
the order links first appear.

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
