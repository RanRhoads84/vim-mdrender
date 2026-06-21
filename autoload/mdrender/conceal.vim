vim9script

import autoload 'mdrender/config.vim' as Cfg

# ── Syntax group names owned by this layer ────────────────────────────────────
#
# Keeping an explicit list here makes Teardown() reliable — we only clear
# groups we created, leaving Vim's built-in markdown syntax untouched.

const OWNED_GROUPS = [
  'MdH1Mark', 'MdH1', 'MdH2Mark', 'MdH2', 'MdH3Mark', 'MdH3',
  'MdH4Mark', 'MdH4', 'MdH5Mark', 'MdH5', 'MdH6Mark', 'MdH6',
  'MdBold', 'MdBoldDelim',
  'MdItalic', 'MdItalicDelim',
  'MdBoldItalic', 'MdBoldItalicDelim',
  'MdCodeInlineMark',
  'MdStrike', 'MdStrikeDelim',
  'MdLinkLabel', 'MdLinkDelimOpen', 'MdLinkURL',
  'MdListBullet', 'MdTaskTodo', 'MdTaskDone',
  'MdBlockquoteMark',
]

# ── Public API ────────────────────────────────────────────────────────────────

# Install syntax rules into the current buffer.
# Each sub-function is guarded by the corresponding element flag so users
# can opt out of individual elements via g:mdrender_elements.
export def Apply()
  var el = Cfg.Elements()

  if el.headings
    _Headings()
  endif
  if el.bold || el.italic
    _Emphasis(el.bold, el.italic)
  endif
  if el.code_inline
    _CodeInline()
  endif
  if el.strikethrough
    _Strikethrough()
  endif
  if el.links
    _Links()
  endif
  if el.lists || el.tasks
    _Lists(el.lists, el.tasks)
  endif
  if el.blockquotes
    _Blockquotes()
  endif
enddef

# Remove all plugin-owned syntax groups from the current buffer.
export def Teardown()
  for g in OWNED_GROUPS
    try
      execute 'syntax clear ' .. g
    catch /E28/
      # Group did not exist — safe to ignore.
    endtry
  endfor
enddef

# ── Private helpers ───────────────────────────────────────────────────────────

# Headings: conceal the leading `# ` marker; highlight the rest of the line.
#
# The marker pattern `^#{N} ` is unambiguous per heading level because a
# line starting with `## text` has two # chars followed by a space — the
# H1 pattern `^# ` does not match it (the second char is `#`, not ` `).
def _Headings()
  for level in [1, 2, 3, 4, 5, 6]
    var hashes    = repeat('#', level)
    var mark_grp  = 'MdH' .. level .. 'Mark'
    var head_grp  = 'MdH' .. level
    execute 'syntax match ' .. mark_grp
          .. ' /^' .. hashes .. ' / contained conceal'
    execute 'syntax match ' .. head_grp
          .. ' /^' .. hashes .. ' .*$/ contains=' .. mark_grp
  endfor
enddef

# Bold, italic, bold-italic via concealends on matchgroup regions.
#
# `concealends` hides the start/end patterns of a region while showing
# the body — exactly what is needed for **bold** markers. The `matchgroup`
# names the highlight applied to the delimiters; it does not need to be a
# Conceal-linked group because `concealends` handles the hiding.
#
# Priority: bold-italic (***) must be defined before bold (**) and italic (*)
# to prevent the two-star opener from being consumed first.
def _Emphasis(do_bold: bool, do_italic: bool)
  if do_bold && do_italic
    execute 'syntax region MdBoldItalic matchgroup=MdBoldItalicDelim'
          .. ' start=/\*\*\*\ze\S/ end=/\S\zs\*\*\*/ oneline concealends'
  endif

  if do_bold
    execute 'syntax region MdBold matchgroup=MdBoldDelim'
          .. ' start=/\*\*\ze\S/ end=/\S\zs\*\*/ oneline concealends'
    execute 'syntax region MdBold matchgroup=MdBoldDelim'
          .. ' start=/__\ze\S/ end=/\S\zs__/ oneline concealends'
  endif

  if do_italic
    execute 'syntax region MdItalic matchgroup=MdItalicDelim'
          .. ' start=/\*\ze[^*\s]/ end=/[^*\s]\zs\*/ oneline concealends'
    execute 'syntax region MdItalic matchgroup=MdItalicDelim'
          .. ' start=/_\ze[^_\s]/ end=/[^_\s]\zs_/ oneline concealends'
  endif
enddef

# Inline code: conceal the surrounding backticks.
def _CodeInline()
  execute 'syntax region MdCodeInline matchgroup=MdCodeInlineMark'
        .. ' start=/`/ end=/`/ oneline concealends'
enddef

# Strikethrough: conceal ~~ delimiters.
def _Strikethrough()
  execute 'syntax region MdStrike matchgroup=MdStrikeDelim'
        .. ' start=/\~\~\ze\S/ end=/\S\zs\~\~/ oneline concealends'
enddef

# Links: [label](url) — conceal the `[`, `](url)` so only the label shows.
#
# The region spans from `[` to the closing `)`. Two contained matches
# conceal the brackets and URL, leaving the label text visible with
# the MdLinkLabel highlight applied by the outer region's group name.
def _Links()
  execute 'syntax match MdLinkDelimOpen /\[/ contained conceal'
  execute 'syntax match MdLinkURL /\](.\{-})/ contained conceal'
  execute 'syntax region MdLinkLabel'
        .. ' start=/\[/ end=/)/'
        .. ' contains=MdLinkDelimOpen,MdLinkURL'
        .. ' oneline keepend'
enddef

# Lists: replace bullet chars with Unicode; task checkboxes with ☐ / ☑.
#
# Task patterns must be defined first — they are more specific supersets
# of the plain list pattern, and Vim's syntax engine uses first-match
# priority for overlapping patterns at the same column.
def _Lists(do_lists: bool, do_tasks: bool)
  if do_tasks
    execute 'syntax match MdTaskDone'
          .. ' /^\s*[-*+] \[x\] / conceal cchar=☑'
    execute 'syntax match MdTaskTodo'
          .. ' /^\s*[-*+] \[ \] / conceal cchar=☐'
  endif
  if do_lists
    # `cchar` replaces the concealed text with the given character.
    # A single • is used here; indent-depth-aware bullets are handled
    # by the props layer which can inspect the indent meta from the parser.
    execute 'syntax match MdListBullet /^\s*[-*+]\ze / conceal cchar=•'
  endif
enddef

# Blockquotes: conceal `> ` and replace with a ┃ bar character.
def _Blockquotes()
  execute 'syntax match MdBlockquoteMark /^> / conceal cchar=┃'
enddef
