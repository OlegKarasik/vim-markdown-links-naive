function! s:parse_reference_definition(line) abort
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

function! s:get_or_add_reference(link_key, entry, key_to_index, ordered_refs) abort
  if !has_key(a:key_to_index, a:link_key)
    call add(a:ordered_refs, a:entry)
    let a:key_to_index[a:link_key] = len(a:ordered_refs)
  endif
  return a:key_to_index[a:link_key]
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
    let l:def = s:parse_reference_definition(l:line)
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
  let l:converted_lines = []
  let l:token_pattern = '\v\[[^][]+\]\([^()]+\)|\[[^][]+\]\[[^][]*\]'

  for l:line in l:body_lines
    let l:rebuilt = ''
    let l:start = 0

    while 1
      let l:m = matchstrpos(l:line, l:token_pattern, l:start)
      let l:token = l:m[0]
      let l:from = l:m[1]
      let l:to = l:m[2]

      if l:from < 0
        let l:rebuilt .= strpart(l:line, l:start)
        break
      endif

      let l:rebuilt .= strpart(l:line, l:start, l:from - l:start)

      if l:from > 0 && strpart(l:line, l:from - 1, 1) ==# '!'
        let l:rebuilt .= l:token
        let l:start = l:to
        continue
      endif

      if l:token =~# '\v^\[[^][]+\]\([^()]+\)$'
        let l:text = matchstr(l:token, '\v^\[\zs[^][]+\ze\]\(')
        let l:inside = matchstr(l:token, '\v\]\(\zs[^()]+\ze\)$')
        let l:url = matchstr(l:inside, '^\S\+')
        let l:title = substitute(l:inside, '^\S\+\s*', '', '')

        if empty(l:url)
          let l:rebuilt .= l:token
        else
          let l:link_key = l:url . "\t" . l:title
          let l:index = s:get_or_add_reference(
                \ l:link_key,
                \ {'url': l:url, 'title': l:title},
                \ l:key_to_index,
                \ l:ordered_refs
                \ )
          let l:rebuilt .= '[' . l:text . '][' . l:index . ']'
        endif
      else
        let l:text = matchstr(l:token, '\v^\[\zs[^][]+\ze\]\[')
        let l:label = matchstr(l:token, '\v\]\[\zs[^][]*\ze\]$')
        if empty(l:label)
          let l:label = l:text
        endif

        let l:label_key = tolower(l:label)
        if !has_key(l:definitions_by_label, l:label_key)
          let l:rebuilt .= l:token
        else
          let l:used_definition_labels[l:label_key] = 1
          let l:def = l:definitions_by_label[l:label_key]
          let l:link_key = l:def.url . "\t" . l:def.title
          let l:index = s:get_or_add_reference(
                \ l:link_key,
                \ {'url': l:def.url, 'title': l:def.title},
                \ l:key_to_index,
                \ l:ordered_refs
                \ )
          let l:rebuilt .= '[' . l:text . '][' . l:index . ']'
        endif
      endif

      let l:start = l:to
    endwhile

    call add(l:converted_lines, l:rebuilt)
  endfor

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
