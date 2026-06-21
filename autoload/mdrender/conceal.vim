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
  'MdHRuleMark',
  'MdCodeFenceMark',
]

# ── Public API ────────────────────────────────────────────────────────────────

# Install syntax rules into the current buffer.
# Each sub-function is guarded by the corresponding element flag so users
# can opt out of individual elements via g:mdrender_elements.
export def Apply()
  var el = Cfg.Elements()

  if el.headings
    Headings_()
  endif
  if el.bold || el.italic
    Emphasis_(el.bold, el.italic)
  endif
  if el.code_inline
    CodeInline_()
  endif
  if el.code_block
    CodeFence_()
  endif
  if el.strikethrough
    Strikethrough_()
  endif
  if el.links
    Links_()
  endif
  if el.lists || el.tasks
    Lists_(el.lists, el.tasks)
  endif
  if el.blockquotes
    Blockquotes_()
  endif
  if el.hr
    Hr_()
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
def Headings_()
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
# Vim gives priority to the LAST-defined syntax item when multiple match at
# the same column. Bold and italic are defined first so that bold-italic
# (defined last) wins over plain bold at `***text***`.
def Emphasis_(do_bold: bool, do_italic: bool)
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

  if do_bold && do_italic
    execute 'syntax region MdBoldItalic matchgroup=MdBoldItalicDelim'
          .. ' start=/\*\*\*\ze\S/ end=/\S\zs\*\*\*/ oneline concealends'
  endif
enddef

# Inline code: conceal the surrounding backticks.
# The start pattern `\ze[^`]` prevents matching the first backtick of a
# triple-backtick fence (``` opens a fence, not an inline span).
def CodeInline_()
  execute 'syntax region MdCodeInline matchgroup=MdCodeInlineMark'
        .. ' start=/`\ze[^`]/ end=/`/ oneline concealends'
enddef

# Fenced code blocks: conceal the ``` / ~~~ fence delimiter lines.
# These must be defined AFTER CodeInline_ so that the fence pattern,
# being last-defined, wins over the inline-code region at the same column.
def CodeFence_()
  execute 'syntax match MdCodeFenceMark /^```\S*\s*$/ conceal'
  execute 'syntax match MdCodeFenceMark /^\~\~\~\S*\s*$/ conceal'
enddef

# Strikethrough: conceal ~~ delimiters.
def Strikethrough_()
  execute 'syntax region MdStrike matchgroup=MdStrikeDelim'
        .. ' start=/\~\~\ze\S/ end=/\S\zs\~\~/ oneline concealends'
enddef

# Links: [label](url) — conceal the `[`, `](url)` so only the label shows.
#
# The region spans from `[` to the closing `)`. Two contained matches
# conceal the brackets and URL, leaving the label text visible with
# the MdLinkLabel highlight applied by the outer region's group name.
def Links_()
  execute 'syntax match MdLinkDelimOpen /\[/ contained conceal'
  execute 'syntax match MdLinkURL /\](.\{-})/ contained conceal'
  execute 'syntax region MdLinkLabel'
        .. ' start=/\[/ end=/)/'
        .. ' contains=MdLinkDelimOpen,MdLinkURL'
        .. ' oneline keepend'
enddef

# Lists: replace bullet chars with Unicode; task checkboxes with ☐ / ☑.
#
# Vim gives priority to the LAST-defined pattern when two patterns start at
# the same column. Tasks must therefore be defined AFTER the plain bullet
# so that `- [x] ` is consumed by MdTaskDone rather than MdListBullet.
def Lists_(do_lists: bool, do_tasks: bool)
  if do_lists
    execute 'syntax match MdListBullet /^\s*[-*+]\ze / conceal cchar=•'
  endif
  if do_tasks
    # Stop before the trailing space so `☑ task text` retains its space.
    execute 'syntax match MdTaskDone'
          .. ' /^\s*[-*+] \[x\]/ conceal cchar=☑'
    execute 'syntax match MdTaskTodo'
          .. ' /^\s*[-*+] \[ \]/ conceal cchar=☐'
  endif
enddef

# Blockquotes: conceal `> ` and replace with a ┃ bar character.
def Blockquotes_()
  execute 'syntax match MdBlockquoteMark /^> / conceal cchar=┃'
enddef

# Horizontal rules: conceal the raw `---` / `***` / `___` line so the
# props layer can inject virtual text in its place without overlap.
def Hr_()
  execute 'syntax match MdHRuleMark /^[-*_]\{3,}\s*$/ conceal'
enddef
