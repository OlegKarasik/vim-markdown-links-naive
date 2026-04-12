# Rules

1. DO NOT create or edit files outside of repository.
2. DO NOT redirect output from commands into files outside of repository.
3. DO NOT take dependencies on other plugins.
4. Keep standard Vim plugin layout (`plugin/` and `autoload/`).
5. Public executable command must expose a `<Plug>(...)` mapping target.

# Startup

During startup (`plugin/vim_markdown_links_naive.vim`), the plugin:

1. Uses `g:loaded_vim_markdown_links_naive` guard to avoid double loading.
2. Registers command: `:MarkdownLinksAsReferences`.
3. Registers mapping target: `<Plug>(MarkdownLinksAsReferences)` which calls
   `vim_markdown_links_naive#convert()`.

# Concepts

## Convertible Markdown Tokens

The converter rewrites only these token forms:

1. Inline link: `[text](url [title])`
2. Reference link: `[text][label]`
3. Collapsed reference link: `[text][]` (label defaults to `text`)

Image tokens are skipped: if a token is immediately prefixed by `!`, it is kept
as-is.

## Reference Definition Lines

Definition lines are parsed from full-buffer input using this shape:

1. `[label]: url`
2. `[label]: url title`

Rules:

1. Leading spaces before `[` are accepted.
2. URL is parsed as first non-space token after `:`.
3. Remaining text is treated as title (leading spaces trimmed).
4. Labels are matched case-insensitively.
5. For duplicate labels, first definition wins.

## Numbered Reference Identity

Generated numbered references are deduplicated by:

1. `url + "\t" + title`

So two links with same URL but different titles become different numbered
definitions.

## No-op and Error Behavior

1. If buffer is non-modifiable or readonly, command errors with:
   `vim-markdown-links-naive: current buffer is not modifiable`
2. If no links are converted, buffer is left unchanged and warning is shown:
   `vim-markdown-links-naive: no markdown links were converted`

# Command

## MarkdownLinksAsReferences

Calls `vim_markdown_links_naive#convert()`.

Execution flow:

1. Reads full buffer.
2. Splits input into:
   1. body lines (non-definition lines)
   2. known reference definitions (first per label, case-insensitive)
3. Scans body lines token-by-token.
4. Rewrites:
   1. inline links to `[text][N]`
   2. reference links with known labels to `[text][N]`
   3. unknown reference labels unchanged
   4. image links unchanged
5. Appends generated numbered definitions at document bottom.
6. Appends unused original definitions (labels never consumed by reference-link
   conversion), preserving original definition order and label text.
7. Replaces entire buffer content and deletes old trailing lines if needed.

# Plug Mappings

1. `<Plug>(MarkdownLinksAsReferences)`

# Public Vimscript Functions

## `vim_markdown_links_naive#convert()`

Public conversion entry point for both command and `<Plug>` mapping.

# Internal Script-Local Functions

## `s:vim_markdown_links_naive_parse_reference_definition(line)`

Parses one line and returns:

1. `{}` when line is not a reference definition
2. `{ "label": ..., "url": ..., "title": ... }` when parse succeeds

## `s:vim_markdown_links_naive_get_or_add_reference(link_key, entry, key_to_index, ordered_refs)`

Maintains ordered unique numbered references and returns 1-based reference
index.

## `s:vim_markdown_links_naive_warn(message)`

Shows warning with Vim built-in warning output (`echohl WarningMsg` +
`echomsg`), prefixed with `vim-markdown-links-naive:`.
