" Feature guard runs in legacy mode, before vim9script is parsed.
" This ensures a clean error on Neovim or Vim < 9.0 rather than a
" cryptic parse failure on the vim9script declaration itself.
if !has('vim9script') || v:version < 900
  echohl ErrorMsg
  echom 'vim-mdrender requires Vim 9.0+'
  echohl None
  finish
endif

vim9script

# Guard against double-loading.
if exists('g:loaded_mdrender') | finish | endif
g:loaded_mdrender = 1

if !has('textprop') || !has('conceal') || !has('timers')
  echohl ErrorMsg
  echom 'vim-mdrender requires +textprop +conceal +timers (use a +huge build)'
  echohl None
  finish
endif

# ── Autocommands ────────────────────────────────────────────────────────────
#
# FileType markdown   — primary activation trigger; called when a markdown
#                       buffer's filetype is set for the first time.
# BufWinEnter         — re-render when a markdown buffer is displayed in a
#                       new window (e.g. :split, :tabnew).
# WinScrolled         — re-render the newly visible range after scrolling.
# TextChanged[I]      — schedule a debounced re-render after edits.
# CursorMoved[I]      — reveal raw source on the cursor line so the user
#                       can see what they are editing.

augroup MdRender
  autocmd!
  autocmd FileType markdown            call mdrender#Enable()
  autocmd BufWinEnter *.md,*.markdown  call mdrender#OnBufWinEnter()
  autocmd WinScrolled *.md,*.markdown  call mdrender#OnScroll()
  autocmd TextChanged *.md,*.markdown  call mdrender#OnTextChanged()
  autocmd TextChangedI *.md,*.markdown call mdrender#OnTextChanged()
  autocmd CursorMoved *.md,*.markdown  call mdrender#OnCursorMoved()
  autocmd CursorMovedI *.md,*.markdown call mdrender#OnCursorMoved()
  # Most colorschemes call `hi clear` on load, which wipes all linked groups.
  # Re-run Setup() so MdXxx groups survive every theme switch.
  autocmd ColorScheme *                call mdrender#OnColorScheme()
augroup END

# ── User commands ────────────────────────────────────────────────────────────
command! MdRenderEnable  call mdrender#Enable()
command! MdRenderDisable call mdrender#Disable()
command! MdRenderToggle  call mdrender#Toggle()
