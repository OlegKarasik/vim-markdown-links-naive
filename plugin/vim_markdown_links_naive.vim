if exists('g:loaded_vim_markdown_links_naive')
  finish
endif
let g:loaded_vim_markdown_links_naive = 1

command! -bar -nargs=0 MarkdownLinksAsReferences call vim_markdown_links_naive#convert()
call vim_markdown_links_naive#register_plug_mappings()
