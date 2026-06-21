vim9script

import autoload 'mdrender/config.vim' as Cfg
import autoload 'mdrender/parser.vim' as Parser

# ── Text-property type names ──────────────────────────────────────────────────
#
# All type names are prefixed with `mdrender_` to avoid collisions with
# other plugins. Types are registered once per Vim session (idempotent).

const TYPE_CODEBLOCK   = 'mdrender_codeblock'
const TYPE_HR          = 'mdrender_hr'
const TYPE_BLOCKQUOTE  = 'mdrender_blockquote'
const TYPE_TBL_HEADER  = 'mdrender_tableheader'
const TYPE_TBL_SEP     = 'mdrender_tablesep'

# ── Public API ────────────────────────────────────────────────────────────────

# Register all text-property types with Vim.
# Safe to call multiple times — EnsureType_() skips already-registered types.
export def RegisterTypes()
  EnsureType_(TYPE_CODEBLOCK,  {highlight: 'MdCodeBlock'})
  EnsureType_(TYPE_HR,         {highlight: 'MdHRule'})
  EnsureType_(TYPE_BLOCKQUOTE, {highlight: 'MdBlockquote'})
  EnsureType_(TYPE_TBL_HEADER, {highlight: 'MdTableHeader'})
  EnsureType_(TYPE_TBL_SEP,    {highlight: 'MdTableBorder'})
enddef

# Walk a token list and attach text properties to bufnr.
#
# Called after ParseRange() produces tokens for the visible window range.
# Always clears existing props in the affected range first so re-renders
# don't accumulate duplicate decorations.
export def Apply(bufnr: number, tokens: list<dict<any>>)
  if empty(tokens)
    return
  endif

  var el = Cfg.Elements()
  ClearRange_(bufnr, tokens[0].lnum, tokens[-1].lnum)

  var i = 0
  while i < len(tokens)
    var tok = tokens[i]

    # ── Fenced code block background ─────────────────────────────────────
    # Apply MdCodeBlock to every body line between the opening and closing
    # fence markers. The fence lines themselves are handled by the conceal
    # layer (they are hidden), so we only decorate the body.
    if el.code_block && tok.type == Parser.T_FENCE_START
      var j = i + 1
      while j < len(tokens) && tokens[j].type == Parser.T_FENCE_BODY
        var body_lnum = tokens[j].lnum
        var line_end  = len(getbufline(bufnr, body_lnum)[0]) + 1
        prop_add(body_lnum, 1, {
          bufnr:    bufnr,
          type:     TYPE_CODEBLOCK,
          end_lnum: body_lnum,
          end_col:  line_end,
        })
        j += 1
      endwhile

    # ── Horizontal rule ───────────────────────────────────────────────────
    # Inject virtual text spanning the window width. The conceal layer
    # hides the raw `---` / `***` / `___` content; this prop adds the
    # visual replacement. text_align requires col=0 (E1294 otherwise).
    elseif el.hr && tok.type == Parser.T_HR
      prop_add(tok.lnum, 0, {
        bufnr:      bufnr,
        type:       TYPE_HR,
        text:       repeat('─', winwidth(0)),
        text_align: 'right',
      })

    # ── Table header row ──────────────────────────────────────────────────
    # A table row immediately followed by a separator line is a header.
    # Apply MdTableHeader background across the full line.
    elseif el.tables && tok.type == Parser.T_TABLE_ROW
      if i + 1 < len(tokens) && tokens[i + 1].type == Parser.T_TABLE_SEP
        var line_end = len(getbufline(bufnr, tok.lnum)[0]) + 1
        prop_add(tok.lnum, 1, {
          bufnr:    bufnr,
          type:     TYPE_TBL_HEADER,
          end_lnum: tok.lnum,
          end_col:  line_end,
        })
      endif

    # ── Table separator row ───────────────────────────────────────────────
    # Apply MdTableBorder highlight to the |---|---| line.
    elseif el.tables && tok.type == Parser.T_TABLE_SEP
      var line_end = len(getbufline(bufnr, tok.lnum)[0]) + 1
      prop_add(tok.lnum, 1, {
        bufnr:    bufnr,
        type:     TYPE_TBL_SEP,
        end_lnum: tok.lnum,
        end_col:  line_end,
      })

    endif

    i += 1
  endwhile
enddef

# Remove all plugin text properties from bufnr entirely.
# Called on :MdRenderDisable.
export def Teardown(bufnr: number)
  ClearAll_(bufnr)
enddef

# ── Private helpers ───────────────────────────────────────────────────────────

def ClearRange_(bufnr: number, top: number, bot: number)
  for t in AllTypes_()
    prop_remove({type: t, bufnr: bufnr, all: 1, start_lnum: top, end_lnum: bot})
  endfor
enddef

def ClearAll_(bufnr: number)
  for t in AllTypes_()
    prop_remove({type: t, bufnr: bufnr, all: 1})
  endfor
enddef

def EnsureType_(name: string, opts: dict<any>)
  if empty(prop_type_get(name))
    prop_type_add(name, opts)
  endif
enddef

def AllTypes_(): list<string>
  return [TYPE_CODEBLOCK, TYPE_HR, TYPE_BLOCKQUOTE, TYPE_TBL_HEADER, TYPE_TBL_SEP]
enddef
