vim9script

import autoload 'mdrender/config.vim'    as Cfg
import autoload 'mdrender/highlight.vim' as Hl
import autoload 'mdrender/parser.vim'    as Parser
import autoload 'mdrender/conceal.vim'   as Conceal
import autoload 'mdrender/props.vim'     as Props

# ── Per-buffer state ──────────────────────────────────────────────────────────
#
# Keyed by string(bufnr). Each entry:
#   enabled        bool   — whether rendering is active for this buffer
#   conceal_save   number — user's 'conceallevel' before we changed it
#   timer_id       number — pending debounce timer id (-1 if none)
#   cursor_lnum    number — last cursor line seen (avoids redundant moves)

var _state: dict<dict<any>> = {}

# ── Public API — called from plugin/mdrender.vim ──────────────────────────────

export def Enable()
  if !Cfg.Get('enabled', 1)
    return
  endif

  var bufnr = bufnr('%')

  if FileTooLarge_(bufnr)
    return
  endif

  # Initialise highlight groups and prop types (both are idempotent).
  Hl.Setup()
  Props.RegisterTypes()

  # Install syntax conceal rules into this buffer.
  Conceal.Apply()

  # Save and override conceallevel.
  var cl_save = &l:conceallevel
  setlocal conceallevel=2

  # concealcursor="" means the cursor line is always shown unconcealed,
  # giving the user a clear view of what they are editing.
  setlocal concealcursor=

  _state[string(bufnr)] = {
    enabled:      true,
    conceal_save: cl_save,
    timer_id:     -1,
    cursor_lnum:  -1,
  }

  Render_(bufnr)
enddef

export def Disable()
  var bufnr = bufnr('%')
  var key   = string(bufnr)

  if !has_key(_state, key)
    return
  endif

  var st = _state[key]

  # Cancel any pending debounce timer.
  if st.timer_id >= 0
    timer_stop(st.timer_id)
  endif

  Conceal.Teardown()
  Props.Teardown(bufnr)
  Hl.Teardown()

  # Restore the user's original conceallevel.
  execute 'setlocal conceallevel=' .. st.conceal_save

  remove(_state, key)
enddef

export def Toggle()
  var key = string(bufnr('%'))
  if has_key(_state, key) && _state[key].enabled
    Disable()
  else
    Enable()
  endif
enddef

# ── Autocmd handlers ──────────────────────────────────────────────────────────

export def OnBufWinEnter()
  var bufnr = bufnr('%')
  if IsEnabled_(bufnr)
    Render_(bufnr)
  endif
enddef

export def OnScroll()
  var bufnr = bufnr('%')
  if IsEnabled_(bufnr)
    Render_(bufnr)
  endif
enddef

# Debounced: wait `g:mdrender_debounce_ms` ms of inactivity before re-rendering.
# This prevents a full re-render on every keystroke while the user is typing.
export def OnTextChanged()
  var bufnr = bufnr('%')
  var key   = string(bufnr)
  if !has_key(_state, key) || !_state[key].enabled
    return
  endif

  var st    = _state[key]
  if st.timer_id >= 0
    timer_stop(st.timer_id)
    st.timer_id = -1
  endif

  var delay = Cfg.Get('debounce_ms', 150)
  st.timer_id = timer_start(delay, (_) => OnDebounceExpired_(bufnr))
enddef

# Reveal the raw source on the cursor line so the user can see the markers
# they are editing. We do this by tracking the cursor line — the actual
# reveal is handled by 'concealcursor' being empty (set in Enable()).
export def OnColorScheme()
  Hl.Setup()
enddef

export def OnCursorMoved()
  if !Cfg.Get('cursor_reveal', 1)
    return
  endif

  var bufnr = bufnr('%')
  var key   = string(bufnr)
  if !has_key(_state, key) || !_state[key].enabled
    return
  endif

  var st   = _state[key]
  var lnum = line('.')
  if lnum != st.cursor_lnum
    st.cursor_lnum = lnum
  endif
enddef

# ── Private helpers ───────────────────────────────────────────────────────────
#
# Vim9 script requires all script-level `def` functions to start with an
# uppercase letter. Trailing underscores mark these as plugin-private.

def OnDebounceExpired_(bufnr: number)
  var key = string(bufnr)
  if has_key(_state, key)
    _state[key].timer_id = -1
  endif
  Render_(bufnr)
enddef

# Core render loop:
#  1. Determine the visible window range via getwininfo().
#  2. Extend the range by `g:mdrender_render_pad` lines on each side.
#  3. Parse the range with the line-state machine.
#  4. Apply text properties for block elements.
#
# The conceal (syntax) layer is installed once in Enable() and requires no
# per-render work — Vim's syntax engine handles it on every redraw automatically.
def Render_(bufnr: number)
  var winid = bufwinid(bufnr)
  if winid < 0
    return
  endif

  var info = getwininfo(winid)
  if empty(info)
    return
  endif

  var pad = Cfg.Get('render_pad', 50)
  var top = max([1, info[0].topline - pad])
  var bot = min([line('$'), info[0].botline + pad])

  var tokens = Parser.ParseRange(bufnr, top, bot)
  Props.Apply(bufnr, tokens)
enddef

def IsEnabled_(bufnr: number): bool
  var key = string(bufnr)
  return has_key(_state, key) && _state[key].enabled
enddef

def FileTooLarge_(bufnr: number): bool
  var limit = Cfg.Get('max_file_size', 204800)
  return getfsize(bufname(bufnr)) > limit
enddef
