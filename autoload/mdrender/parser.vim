vim9script

# ── Line-type constants ───────────────────────────────────────────────────────
#
# Each constant names the structural role of a line as classified by
# ParseRange(). Callers pattern-match on these to decide which rendering
# action to apply.

export const T_BLANK          = 'blank'
export const T_HEADING        = 'heading'
export const T_FENCE_START    = 'fence_start'
export const T_FENCE_BODY     = 'fence_body'
export const T_FENCE_END      = 'fence_end'
export const T_BLOCKQUOTE     = 'blockquote'
export const T_LIST_UL        = 'list_ul'
export const T_LIST_OL        = 'list_ol'
export const T_LIST_TASK_TODO = 'list_task_todo'
export const T_LIST_TASK_DONE = 'list_task_done'
export const T_HR             = 'hr'
export const T_TABLE_ROW      = 'table_row'
export const T_TABLE_SEP      = 'table_sep'
export const T_PARAGRAPH      = 'paragraph'

# ── ParseRange ────────────────────────────────────────────────────────────────
#
# Classify lines [top, bot] in bufnr, returning a list of token dicts:
#
#   { lnum: int, type: string, meta: dict<any> }
#
# The parser is a single-pass line-state machine. The only persistent
# state between lines is whether we are inside a fenced code block, because
# the fence changes how every subsequent line is interpreted until a
# matching closing fence is found.
#
# Inline elements (bold, italic, links, etc.) are NOT parsed here — they
# are handled by Vim's syntax engine in conceal.vim.
#
# meta keys by type:
#   heading        {level: 1-6}
#   fence_start    {lang: string}   (lang may be empty)
#   fence_body     {lang: string}   (inherited from the opening fence)
#   fence_end      {lang: string}
#   list_ul        {indent: int}    (leading-spaces count)
#   list_ol        {indent: int, num: string}
#   list_task_*    {indent: int}
#   (all others)   {}

export def ParseRange(bufnr: number, top: number, bot: number): list<dict<any>>
  var tokens: list<dict<any>> = []
  var in_fence    = false
  var fence_fence = ''   # the opening fence character (` or ~)
  var fence_lang  = ''

  var lnum = top
  while lnum <= bot
    var line = getbufline(bufnr, lnum)[0]
    var tok: dict<any>

    if in_fence
      # Closing fence: same character repeated ≥3 times, optional trailing space
      var close_pat = '^' .. fence_fence .. '\{3,}\s*$'
      if line =~# close_pat
        tok = {lnum: lnum, type: T_FENCE_END, meta: {lang: fence_lang}}
        in_fence    = false
        fence_fence = ''
        fence_lang  = ''
      else
        tok = {lnum: lnum, type: T_FENCE_BODY, meta: {lang: fence_lang}}
      endif

    elseif line =~# '^\s*$'
      tok = {lnum: lnum, type: T_BLANK, meta: {}}

    elseif line =~# '^```'
      var lang = matchstr(line, '^```\zs\S*')
      tok = {lnum: lnum, type: T_FENCE_START, meta: {lang: lang}}
      in_fence    = true
      fence_fence = '`'
      fence_lang  = lang

    elseif line =~# '^~~~'
      var lang = matchstr(line, '^~~~\zs\S*')
      tok = {lnum: lnum, type: T_FENCE_START, meta: {lang: lang}}
      in_fence    = true
      fence_fence = '~'
      fence_lang  = lang

    elseif line =~# '^#\{1,6\} '
      var level = len(matchstr(line, '^#\+'))
      tok = {lnum: lnum, type: T_HEADING, meta: {level: level}}

    elseif line =~# '^> '
      tok = {lnum: lnum, type: T_BLOCKQUOTE, meta: {}}

    # Task items must be tested before plain list items so [x]/[ ] are caught.
    elseif line =~# '^\s*[-*+] \[x\] '
      tok = {lnum: lnum, type: T_LIST_TASK_DONE,
             meta: {indent: len(matchstr(line, '^\s*'))}}

    elseif line =~# '^\s*[-*+] \[ \] '
      tok = {lnum: lnum, type: T_LIST_TASK_TODO,
             meta: {indent: len(matchstr(line, '^\s*'))}}

    elseif line =~# '^\s*[-*+] '
      tok = {lnum: lnum, type: T_LIST_UL,
             meta: {indent: len(matchstr(line, '^\s*'))}}

    elseif line =~# '^\s*\d\+\. '
      tok = {lnum: lnum, type: T_LIST_OL,
             meta: {indent: len(matchstr(line, '^\s*')),
                    num:    matchstr(line, '\d\+')}}

    # HR: a line of three or more identical punctuation chars (-, *, _)
    # with optional surrounding spaces and nothing else.
    elseif line =~# '^[- ]\{3,}$' && line =~# '^-'
      tok = {lnum: lnum, type: T_HR, meta: {}}
    elseif line =~# '^[* ]\{3,}$' && line =~# '^\*'
      tok = {lnum: lnum, type: T_HR, meta: {}}
    elseif line =~# '^[_ ]\{3,}$' && line =~# '^_'
      tok = {lnum: lnum, type: T_HR, meta: {}}

    # Table separator row: |---|---| pattern (cells of dashes, colons, spaces)
    elseif line =~# '^|[-: |]\+|$'
      tok = {lnum: lnum, type: T_TABLE_SEP, meta: {}}

    # Table data row: any line that begins and/or ends with a pipe
    elseif line =~# '^|' || (line =~# '|$' && line =~# '|')
      tok = {lnum: lnum, type: T_TABLE_ROW, meta: {}}

    else
      tok = {lnum: lnum, type: T_PARAGRAPH, meta: {}}
    endif

    tokens->add(tok)
    lnum += 1
  endwhile

  return tokens
enddef
