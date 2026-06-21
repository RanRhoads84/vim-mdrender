vim9script

# ── Highlight group definitions ──────────────────────────────────────────────
#
# All groups use `hi def link` so they automatically follow the active
# colorscheme. `hi def link X Y` is a live pointer: every redraw resolves X
# through Y's current definition, so theme switches take effect immediately
# without any extra work.
#
# Setup() is re-run on every ColorScheme event (see plugin/mdrender.vim)
# because most colorschemes call `hi clear`, which wipes linked groups.
#
# To override a group, define it after your colorscheme loads:
#   autocmd ColorScheme * hi MdH1 guifg=#ff6688 gui=bold

export def Setup()
  # Headings: different semantic groups give a natural colour hierarchy
  # without hardcoding any palette. Title is usually the most prominent;
  # Comment is usually the most muted — matching the H1→H6 importance scale.
  hi def link MdH1 Title
  hi def link MdH2 Statement
  hi def link MdH3 Type
  hi def link MdH4 Special
  hi def link MdH5 Identifier
  hi def link MdH6 Comment

  # Inline emphasis: style only, no colour override. Bold text stays the same
  # colour as Normal — changing colour would contradict what bold means.
  hi def MdBold       gui=bold              cterm=bold
  hi def MdItalic     gui=italic            cterm=italic
  hi def MdBoldItalic gui=bold,italic       cterm=bold,italic
  hi def MdStrike     gui=strikethrough     cterm=strikethrough

  # Code: String for inline spans (already distinctly coloured in most themes),
  # CursorLine for code block backgrounds (a subtle, theme-neutral fill).
  hi def link MdCodeInline  String
  hi def link MdCodeBlock   CursorLine
  hi def link MdCodeLang    Comment

  # Links: Vim's built-in Underlined group is the canonical choice for links.
  hi def link MdLink      Underlined
  hi def link MdLinkDelim NonText

  # Blockquotes: body is secondary content (Comment); the ┃ bar is an accent
  # mark (Special).
  hi def link MdBlockquote     Comment
  hi def link MdBlockquoteMark Special

  # Structural chrome: NonText is intentionally dim (line numbers, tilde
  # column) — the same visual weight fits HR lines and table borders.
  hi def link MdHRule      NonText
  hi def link MdListBullet Special
  hi def link MdTaskTodo   Todo
  hi def link MdTaskDone   Comment

  # Tables
  hi def link MdTableBorder NonText
  hi def link MdTableHeader Statement
enddef

# Remove all plugin-owned highlight groups.
# Called by Disable() so a clean slate is left when rendering is off.
export def Teardown()
  for g in AllGroups_()
    execute 'hi clear ' .. g
  endfor
enddef

def AllGroups_(): list<string>
  return [
    'MdH1', 'MdH2', 'MdH3', 'MdH4', 'MdH5', 'MdH6',
    'MdBold', 'MdItalic', 'MdBoldItalic', 'MdStrike',
    'MdCodeInline', 'MdCodeBlock', 'MdCodeLang',
    'MdLink', 'MdLinkDelim',
    'MdBlockquote', 'MdBlockquoteMark',
    'MdHRule', 'MdListBullet', 'MdTaskTodo', 'MdTaskDone',
    'MdTableBorder', 'MdTableHeader',
  ]
enddef
