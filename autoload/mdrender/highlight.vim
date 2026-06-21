vim9script

# ── Highlight group definitions ──────────────────────────────────────────────
#
# All groups use `hi def` so a user's colorscheme or manual `hi` command
# always wins. Groups are named with the MdXxx prefix to avoid clashing
# with other plugins or Vim's built-in groups.
#
# GUI colours are from the One Dark palette (Atom-derived) — a reasonable
# neutral choice that works on both dark and light terminals when the
# cterm fallbacks are set appropriately.

export def Setup()
  # Headings — bold text, a distinct colour per level
  hi def MdH1 gui=bold guifg=#e06c75 cterm=bold ctermfg=203
  hi def MdH2 gui=bold guifg=#e5c07b cterm=bold ctermfg=221
  hi def MdH3 gui=bold guifg=#98c379 cterm=bold ctermfg=114
  hi def MdH4 gui=bold guifg=#56b6c2 cterm=bold ctermfg=73
  hi def MdH5 gui=bold guifg=#61afef cterm=bold ctermfg=75
  hi def MdH6 gui=bold guifg=#c678dd cterm=bold ctermfg=176

  # Inline emphasis
  hi def MdBold       gui=bold               cterm=bold
  hi def MdItalic     gui=italic             cterm=italic
  hi def MdBoldItalic gui=bold,italic        cterm=bold,italic
  hi def MdStrike     gui=strikethrough      cterm=strikethrough

  # Code — inline spans get a subtle background; block background only
  hi def MdCodeInline  guifg=#e06c75 guibg=#2d2d2d ctermfg=203 ctermbg=236
  hi def MdCodeBlock   guibg=#2d2d2d ctermbg=236
  hi def MdCodeLang    guifg=#5c6370 ctermfg=242

  # Links — the label is underlined; the URL is dim (it will be concealed)
  hi def MdLink      gui=underline guifg=#61afef cterm=underline ctermfg=75
  hi def MdLinkDelim guifg=#5c6370 ctermfg=242

  # Blockquotes
  hi def MdBlockquote     guifg=#abb2bf ctermfg=145
  hi def MdBlockquoteMark guifg=#61afef ctermfg=75

  # Structural / decorative
  hi def MdHRule      guifg=#4b5263 ctermfg=239
  hi def MdListBullet guifg=#e06c75 ctermfg=203
  hi def MdTaskTodo   guifg=#e5c07b ctermfg=221
  hi def MdTaskDone   guifg=#98c379 ctermfg=114

  # Tables
  hi def MdTableBorder guifg=#4b5263 ctermfg=239
  hi def MdTableHeader gui=bold cterm=bold
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
