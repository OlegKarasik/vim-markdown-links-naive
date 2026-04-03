if exists('g:loaded_markdown_links_as_references')
  finish
endif
let g:loaded_markdown_links_as_references = 1

command! -bar -nargs=0 MarkdownLinksAsReferences call markdown_links_as_references#convert()
