vim9script

# Guard against double-loading.
if exists('g:loaded_mdrender') | finish | endif
g:loaded_mdrender = 1

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
augroup END

# ── User commands ────────────────────────────────────────────────────────────
command! MdRenderEnable  call mdrender#Enable()
command! MdRenderDisable call mdrender#Disable()
command! MdRenderToggle  call mdrender#Toggle()
