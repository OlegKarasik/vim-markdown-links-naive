function! s:vim_markdown_links_naive_parse_reference_definition(line) abort
  let l:match = matchlist(a:line, '^\s*\[\([^]]\+\)\]:\s*\(\S\+\)\(\s\+.*\)\?$')
  if empty(l:match)
    return {}
  endif

  let l:title = ''
  if len(l:match) > 3 && !empty(l:match[3])
    let l:title = substitute(l:match[3], '^\s\+', '', '')
  endif

  return {
        \ 'label': l:match[1],
        \ 'url': l:match[2],
        \ 'title': l:title,
        \ }
endfunction

function! s:vim_markdown_links_naive_get_or_add_reference(link_key, entry, key_to_index, ordered_refs) abort
  if !has_key(a:key_to_index, a:link_key)
    call add(a:ordered_refs, a:entry)
    let a:key_to_index[a:link_key] = len(a:ordered_refs)
  endif
  return a:key_to_index[a:link_key]
endfunction

function! s:vim_markdown_links_naive_warn(message) abort
  echohl WarningMsg
  echomsg 'vim-markdown-links-naive: ' . a:message
  echohl None
endfunction

function! vim_markdown_links_naive#register_plug_mappings() abort
  call s:register_plug_mapping(
        \ '<Plug>(MarkdownLinksAsReferences)',
        \ '<Cmd>call vim_markdown_links_naive#convert()<CR>')
endfunction

function! s:register_plug_mapping(lhs, rhs) abort
  if empty(maparg(a:lhs, 'n'))
    execute 'nnoremap <silent> ' . a:lhs . ' ' . a:rhs
  endif
endfunction

function! s:vim_markdown_links_naive_find_balanced_square_close(text, open_index) abort
  let l:depth = 1
  let l:index = a:open_index + 1
  let l:text_len = strlen(a:text)

  while l:index < l:text_len
    let l:character = strpart(a:text, l:index, 1)
    if l:character ==# '['
      let l:depth += 1
    elseif l:character ==# ']'
      let l:depth -= 1
      if l:depth == 0
        return l:index
      endif
    endif
    let l:index += 1
  endwhile

  return -1
endfunction

function! s:vim_markdown_links_naive_next_body_token(text, start) abort
  let l:text_len = strlen(a:text)
  let l:scan = a:start

  while l:scan < l:text_len
    let l:open_bracket = stridx(a:text, '[', l:scan)
    if l:open_bracket < 0
      return {'from': -1, 'to': -1, 'token': '', 'kind': ''}
    endif

    let l:text_close_bracket = s:vim_markdown_links_naive_find_balanced_square_close(a:text, l:open_bracket)
    if l:text_close_bracket < 0 || l:text_close_bracket <= l:open_bracket + 1
      let l:scan = l:open_bracket + 1
      continue
    endif

    let l:text_part = strpart(a:text, l:open_bracket + 1, l:text_close_bracket - l:open_bracket - 1)
    let l:after_text = l:text_close_bracket + 1
    if l:after_text >= l:text_len
      let l:scan = l:open_bracket + 1
      continue
    endif

    let l:separator = strpart(a:text, l:after_text, 1)
    if l:separator ==# '('
      let l:inside_close_paren = stridx(a:text, ')', l:after_text + 1)
      if l:inside_close_paren < 0
        let l:scan = l:open_bracket + 1
        continue
      endif

      let l:inside_part = strpart(a:text, l:after_text + 1, l:inside_close_paren - l:after_text - 1)
      if stridx(l:inside_part, '(') >= 0
        let l:scan = l:open_bracket + 1
        continue
      endif

      let l:token_end = l:inside_close_paren + 1
      return {
            \ 'from': l:open_bracket,
            \ 'to': l:token_end,
            \ 'token': strpart(a:text, l:open_bracket, l:token_end - l:open_bracket),
            \ 'kind': 'inline',
            \ 'text': l:text_part,
            \ 'inside': l:inside_part,
            \ }
    endif

    if l:separator ==# '['
      let l:label_close_bracket = stridx(a:text, ']', l:after_text + 1)
      if l:label_close_bracket < 0
        let l:scan = l:open_bracket + 1
        continue
      endif

      let l:label_part = strpart(a:text, l:after_text + 1, l:label_close_bracket - l:after_text - 1)
      if stridx(l:label_part, '[') >= 0
        let l:scan = l:open_bracket + 1
        continue
      endif

      let l:token_end = l:label_close_bracket + 1
      return {
            \ 'from': l:open_bracket,
            \ 'to': l:token_end,
            \ 'token': strpart(a:text, l:open_bracket, l:token_end - l:open_bracket),
            \ 'kind': 'reference',
            \ 'text': l:text_part,
            \ 'label': l:label_part,
            \ }
    endif

    let l:scan = l:open_bracket + 1
  endwhile

  return {'from': -1, 'to': -1, 'token': '', 'kind': ''}
endfunction

function! vim_markdown_links_naive#convert() abort
  if !&modifiable || &readonly
    echoerr 'vim-markdown-links-naive: current buffer is not modifiable'
    return
  endif

  let l:lines = getline(1, '$')
  let l:body_lines = []
  let l:definitions_by_label = {}
  let l:definition_order = []

  for l:line in l:lines
    let l:def = s:vim_markdown_links_naive_parse_reference_definition(l:line)
    if !empty(l:def)
      let l:key = tolower(l:def.label)
      if !has_key(l:definitions_by_label, l:key)
        let l:definitions_by_label[l:key] = l:def
        call add(l:definition_order, l:key)
      endif
    else
      call add(l:body_lines, l:line)
    endif
  endfor

  let l:key_to_index = {}
  let l:ordered_refs = []
  let l:used_definition_labels = {}
  let l:converted_link_count = 0
  let l:body_text = join(l:body_lines, "\n")
  let l:converted_body_text = ''
  let l:start = 0

  while 1
    let l:token_data = s:vim_markdown_links_naive_next_body_token(l:body_text, l:start)
    let l:token = get(l:token_data, 'token', '')
    let l:from = get(l:token_data, 'from', -1)
    let l:to = get(l:token_data, 'to', -1)

    if l:from < 0
      let l:converted_body_text .= strpart(l:body_text, l:start)
      break
    endif

    let l:converted_body_text .= strpart(l:body_text, l:start, l:from - l:start)

    if l:from > 0 && strpart(l:body_text, l:from - 1, 1) ==# '!'
      let l:converted_body_text .= l:token
      let l:start = l:to
      continue
    endif

    if get(l:token_data, 'kind', '') ==# 'inline'
      let l:text = get(l:token_data, 'text', '')
      let l:inside = get(l:token_data, 'inside', '')
      let l:url = matchstr(l:inside, '^\S\+')
      let l:title = substitute(l:inside, '^\S\+\s*', '', '')

      if empty(l:url)
        let l:converted_body_text .= l:token
      else
        let l:link_key = l:url . "\t" . l:title
        let l:index = s:vim_markdown_links_naive_get_or_add_reference(
              \ l:link_key,
              \ {'url': l:url, 'title': l:title},
              \ l:key_to_index,
              \ l:ordered_refs
              \ )
        let l:converted_body_text .= '[' . l:text . '][' . l:index . ']'
        let l:converted_link_count += 1
      endif
    else
      let l:text = get(l:token_data, 'text', '')
      let l:label = get(l:token_data, 'label', '')
      if empty(l:label)
        let l:label = l:text
      endif

      let l:label_key = tolower(l:label)
      if !has_key(l:definitions_by_label, l:label_key)
        let l:converted_body_text .= l:token
      else
        let l:used_definition_labels[l:label_key] = 1
        let l:def = l:definitions_by_label[l:label_key]
        let l:link_key = l:def.url . "\t" . l:def.title
        let l:index = s:vim_markdown_links_naive_get_or_add_reference(
              \ l:link_key,
              \ {'url': l:def.url, 'title': l:def.title},
              \ l:key_to_index,
              \ l:ordered_refs
              \ )
        let l:converted_body_text .= '[' . l:text . '][' . l:index . ']'
        let l:converted_link_count += 1
      endif
    endif

    let l:start = l:to
  endwhile

  let l:converted_lines = split(l:converted_body_text, "\n", 1)

  if l:converted_link_count == 0
    call s:vim_markdown_links_naive_warn('no markdown links were converted')
    return
  endif

  if !empty(l:ordered_refs)
    if !empty(l:converted_lines) && l:converted_lines[-1] !~# '^\s*$'
      call add(l:converted_lines, '')
    endif

    for l:index in range(0, len(l:ordered_refs) - 1)
      let l:entry = l:ordered_refs[l:index]
      let l:ref_line = '[' . (l:index + 1) . ']: ' . l:entry.url
      if !empty(l:entry.title)
        let l:ref_line .= ' ' . l:entry.title
      endif
      call add(l:converted_lines, l:ref_line)
    endfor
  endif

  let l:unused_defs = []
  for l:key in l:definition_order
    if has_key(l:used_definition_labels, l:key)
      continue
    endif
    let l:def = l:definitions_by_label[l:key]
    let l:line = '[' . l:def.label . ']: ' . l:def.url
    if !empty(l:def.title)
      let l:line .= ' ' . l:def.title
    endif
    call add(l:unused_defs, l:line)
  endfor

  if !empty(l:unused_defs)
    if !empty(l:converted_lines) && l:converted_lines[-1] !~# '^\s*$'
      call add(l:converted_lines, '')
    endif
    call extend(l:converted_lines, l:unused_defs)
  endif

  if empty(l:converted_lines)
    let l:converted_lines = ['']
  endif

  call setline(1, l:converted_lines)
  if line('$') > len(l:converted_lines)
    execute (len(l:converted_lines) + 1) . ',$delete _'
  endif
endfunction
