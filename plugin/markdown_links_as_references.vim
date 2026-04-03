if exists('g:loaded_markdown_links_as_references')
  finish
endif
let g:loaded_markdown_links_as_references = 1

command! MarkdownLinksAsReferences call markdown_links_as_references#convert()
