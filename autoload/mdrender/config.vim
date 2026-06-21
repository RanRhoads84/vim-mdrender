vim9script

# ── Configuration resolution ─────────────────────────────────────────────────
#
# All user-facing options live in g:mdrender_<key> globals. This module
# centralises the lookup so every other module calls Get() rather than
# scattering get(g:, ...) calls throughout the codebase.

# Return the value of g:mdrender_{key}, falling back to `default`.
export def Get(key: string, default: any): any
  return get(g:, 'mdrender_' .. key, default)
enddef

# Return the merged elements table.
#
# The user can set g:mdrender_elements to a partial dict such as
# {'tables': false, 'hr': false} to disable specific elements without
# having to enumerate every key. Unmentioned keys remain at their
# defaults (all enabled).
export def Elements(): dict<bool>
  const defaults: dict<bool> = {
    headings:      true,
    bold:          true,
    italic:        true,
    code_inline:   true,
    code_block:    true,
    links:         true,
    strikethrough: true,
    blockquotes:   true,
    hr:            true,
    lists:         true,
    tasks:         true,
    tables:        true,
  }
  return extendnew(defaults, get(g:, 'mdrender_elements', {}))
enddef

# Return the bullet characters for unordered lists at indent depths 0, 1, 2+.
export def BulletChars(): list<string>
  return Get('bullet_chars', ['•', '◦', '▪'])
enddef
