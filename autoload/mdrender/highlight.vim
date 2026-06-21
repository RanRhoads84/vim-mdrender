vim9script

# ── Built-in themes ──────────────────────────────────────────────────────────
#
# Each theme is a dict of highlight-group → attribute string.
# ApplyTheme_() passes each pair to `hi def <group> <attrs>`, so the format
# is exactly what follows the group name in a :highlight command.
#
# Groups absent from a theme fall through to the `hi def link` defaults set
# later in Setup(), so themes only need to specify what they change.
#
# 'auto'    — not stored here; signals "use the hi def link defaults only"
# 'dark'    — One Dark-inspired opinionated dark palette
# 'light'   — GitHub-inspired opinionated light palette
# 'minimal' — style-only; no colour at all (bold/italic/underline only)

var s_themes: dict<dict<string>> = {
  dark: {
    MdH1:             'guifg=#e06c75 gui=bold              ctermfg=210 cterm=bold',
    MdH2:             'guifg=#e5c07b gui=bold              ctermfg=215 cterm=bold',
    MdH3:             'guifg=#98c379 gui=bold              ctermfg=114 cterm=bold',
    MdH4:             'guifg=#56b6c2                       ctermfg=73',
    MdH5:             'guifg=#61afef                       ctermfg=75',
    MdH6:             'guifg=#abb2bf                       ctermfg=145',
    MdCodeInline:     'guifg=#98c379                       ctermfg=114',
    MdCodeBlock:      'guibg=#2c313a                       ctermbg=236',
    MdCodeLang:       'guifg=#5c6370                       ctermfg=59',
    MdLink:           'guifg=#61afef gui=underline         ctermfg=75  cterm=underline',
    MdLinkDelim:      'guifg=#3e4451                       ctermfg=239',
    MdBlockquote:     'guifg=#5c6370 gui=italic            ctermfg=59  cterm=italic',
    MdBlockquoteMark: 'guifg=#56b6c2                       ctermfg=73',
    MdHRule:          'guifg=#4b5263                       ctermfg=59',
    MdListBullet:     'guifg=#c678dd                       ctermfg=176',
    MdTaskTodo:       'guifg=#e5c07b gui=bold              ctermfg=215 cterm=bold',
    MdTaskDone:       'guifg=#5c6370                       ctermfg=59',
    MdTableBorder:    'guifg=#3e4451                       ctermfg=239',
    MdTableHeader:    'guifg=#e5c07b gui=bold              ctermfg=215 cterm=bold',
  },
  light: {
    MdH1:             'guifg=#b31d28 gui=bold              ctermfg=124 cterm=bold',
    MdH2:             'guifg=#856404 gui=bold              ctermfg=136 cterm=bold',
    MdH3:             'guifg=#116329 gui=bold              ctermfg=22  cterm=bold',
    MdH4:             'guifg=#0550ae                       ctermfg=25',
    MdH5:             'guifg=#6639ba                       ctermfg=91',
    MdH6:             'guifg=#6e7781                       ctermfg=103',
    MdCodeInline:     'guifg=#116329                       ctermfg=22',
    MdCodeBlock:      'guibg=#f6f8fa                       ctermbg=255',
    MdCodeLang:       'guifg=#57606a                       ctermfg=102',
    MdLink:           'guifg=#0550ae gui=underline         ctermfg=25  cterm=underline',
    MdLinkDelim:      'guifg=#d0d7de                       ctermfg=252',
    MdBlockquote:     'guifg=#57606a gui=italic            ctermfg=102 cterm=italic',
    MdBlockquoteMark: 'guifg=#0550ae                       ctermfg=25',
    MdHRule:          'guifg=#d0d7de                       ctermfg=252',
    MdListBullet:     'guifg=#6639ba                       ctermfg=91',
    MdTaskTodo:       'guifg=#856404 gui=bold              ctermfg=136 cterm=bold',
    MdTaskDone:       'guifg=#57606a                       ctermfg=102',
    MdTableBorder:    'guifg=#d0d7de                       ctermfg=252',
    MdTableHeader:    'guifg=#856404 gui=bold              ctermfg=136 cterm=bold',
  },
  minimal: {
    MdH1:             'gui=bold,underline  cterm=bold,underline  guifg=NONE ctermfg=NONE',
    MdH2:             'gui=bold            cterm=bold            guifg=NONE ctermfg=NONE',
    MdH3:             'gui=bold,italic     cterm=bold,italic     guifg=NONE ctermfg=NONE',
    MdH4:             'gui=italic          cterm=italic          guifg=NONE ctermfg=NONE',
    MdH5:             'gui=italic          cterm=italic          guifg=NONE ctermfg=NONE',
    MdH6:             'gui=NONE            cterm=NONE            guifg=NONE ctermfg=NONE',
    MdCodeInline:     'gui=underline       cterm=underline       guifg=NONE ctermfg=NONE',
    MdCodeBlock:      'guibg=NONE ctermbg=NONE',
    MdCodeLang:       'gui=italic          cterm=italic          guifg=NONE ctermfg=NONE',
    MdLink:           'gui=underline       cterm=underline       guifg=NONE ctermfg=NONE',
    MdLinkDelim:      'guifg=NONE ctermfg=NONE',
    MdBlockquote:     'gui=italic          cterm=italic          guifg=NONE ctermfg=NONE',
    MdBlockquoteMark: 'gui=bold            cterm=bold            guifg=NONE ctermfg=NONE',
    MdHRule:          'guifg=NONE ctermfg=NONE',
    MdListBullet:     'guifg=NONE ctermfg=NONE',
    MdTaskTodo:       'gui=bold            cterm=bold            guifg=NONE ctermfg=NONE',
    MdTaskDone:       'gui=NONE            cterm=NONE            guifg=NONE ctermfg=NONE',
    MdTableBorder:    'guifg=NONE ctermfg=NONE',
    MdTableHeader:    'gui=bold,underline  cterm=bold,underline  guifg=NONE ctermfg=NONE',
  },
}

# ── Highlight group definitions ──────────────────────────────────────────────
#
# Setup() first applies any named or inline theme via ApplyTheme_(), then
# falls back to `hi def link` for every group. Because `hi def` only sets a
# group that is not yet defined, the two passes cooperate cleanly:
#
#   • Theme groups: set by ApplyTheme_() with explicit colours/styles.
#   • Auto / unthemed groups: set here via `hi def link` to colorscheme
#     semantic groups so they follow the active theme automatically.
#   • User overrides: `hi def` is a no-op when the group is already defined,
#     so any `hi MdXxx` the user places after this (e.g. in a ColorScheme
#     autocmd that fires after ours) wins unconditionally.
#
# Setup() is re-run on every ColorScheme event (see plugin/mdrender.vim)
# because most colorschemes call `hi clear`, which wipes linked groups.

export def Setup()
  ApplyTheme_()

  # Headings — fall back to semantic groups from the active colorscheme.
  # Title is usually the most prominent; Comment the most muted — matching
  # the H1→H6 importance scale without hardcoding any palette.
  hi def link MdH1 Title
  hi def link MdH2 Statement
  hi def link MdH3 Type
  hi def link MdH4 Special
  hi def link MdH5 Identifier
  hi def link MdH6 Comment

  # Inline emphasis: style only, no colour override, regardless of theme.
  hi def MdBold       gui=bold              cterm=bold
  hi def MdItalic     gui=italic            cterm=italic
  hi def MdBoldItalic gui=bold,italic       cterm=bold,italic
  hi def MdStrike     gui=strikethrough     cterm=strikethrough

  # Code
  hi def link MdCodeInline  String
  hi def link MdCodeBlock   CursorLine
  hi def link MdCodeLang    Comment

  # Links
  hi def link MdLink      Underlined
  hi def link MdLinkDelim NonText

  # Blockquotes
  hi def link MdBlockquote     Comment
  hi def link MdBlockquoteMark Special

  # Structural chrome
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

# Apply g:mdrender_theme if it names a built-in theme or is an inline dict.
# Called at the top of Setup() so theme groups are defined before the
# `hi def link` fallbacks — making those fallbacks no-ops for themed groups.
def ApplyTheme_()
  var raw: any = get(g:, 'mdrender_theme', 'auto')
  var attrs: dict<string>

  if type(raw) == v:t_string
    var name: string = raw
    if name ==# 'auto' || !has_key(s_themes, name)
      return
    endif
    attrs = s_themes[name]
  elseif type(raw) == v:t_dict
    attrs = raw
  else
    return
  endif

  for [group, attr] in items(attrs)
    execute 'hi def ' .. group .. ' ' .. attr
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
