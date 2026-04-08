if exists('g:loaded_vim_markdown_links_naive')
  finish
endif
let g:loaded_vim_markdown_links_naive = 1

nnoremap <silent> <Plug>(MarkdownLinksAsReferences) <Cmd>call vim_markdown_links_naive#convert()<CR>

command! -bar -nargs=0 MarkdownLinksAsReferences call vim_markdown_links_naive#convert()
