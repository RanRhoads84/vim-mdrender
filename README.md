# vim-mdrender

A Vim 9 plugin that renders Markdown files visually inside Vim without modifying buffer content.

## How it works

vim-mdrender applies two display layers on top of your buffer:

1. **Syntax/conceal layer** — inline markers (`**`, `*`, `` ` ``, `~~`, `[]()`）are hidden using Vim's built-in conceal feature.
   Surrounding text receives highlight groups (bold, italic, strikethrough, etc.) via `syntax region ... concealends`.
2. **Text-property layer** — block-level decorations (code block backgrounds, horizontal rules, table header highlighting) applied via `prop_add()` with virtual text.

Toggling the plugin off restores the original display exactly.

## Rendered elements

| Element | Input | Display |
|:--------|:------|:--------|
| Headings H1–H6 | `# ` through `######` | Distinct highlight per level |
| Bold | `**text**` / `__text__` | Markers hidden, text bold |
| Italic | `*text*` / `_text_` | Markers hidden, text italic |
| Bold-italic | `***text***` | Markers hidden, bold + italic |
| Strikethrough | `~~text~~` | Markers hidden, text struck |
| Inline code | `` `code` `` | Markers hidden, string highlight |
| Links | `[label](url)` | URL hidden, label underlined |
| Blockquotes | `> ` | Leading `> ` replaced with `┃` |
| Horizontal rules | `---` / `***` / `___` | Full-width `─────` line |
| Fenced code blocks | 3x backticks / `~~~` | Fence lines hidden, body highlighted |
| Unordered lists | `-` / `*` / `+` | Bullet replaced with `•` / `◦` / `▪` by depth |
| Task lists | `- [x]` / `- [ ]` | `☑` / `☐` |
| Tables | GFM table syntax | Header and separator rows highlighted |

## Requirements

- Vim 9.0+
- `+textprop`, `+conceal`, `+timers` compiled in (present in all `+huge` builds)
- Not compatible with Neovim — Neovim does not support Vim9 script

Verify your build:

```vim
:echo has('textprop') && has('conceal') && has('timers')
```

A result of `1` means your build is compatible.

## Installation

### vim-plug

```vim
Plug 'RanRhoads84/vim-mdrender'
```

### Vim built-in packages

```sh
git clone https://github.com/RanRhoads84/vim-mdrender \
    ~/.vim/pack/plugins/start/vim-mdrender
```

The plugin directory must be on `runtimepath` before Vim's `filetype` detection runs.

## Usage

The plugin activates automatically for any `.md` or `.markdown` file.
The cursor line always shows raw Markdown source so you can see what you are editing.

### Commands

| Command | Effect |
|:--------|:-------|
| `:MdRenderEnable` | Enable rendering in the current buffer |
| `:MdRenderDisable` | Disable and restore the original display |
| `:MdRenderToggle` | Toggle between enabled and disabled |

## Configuration

All variables are optional. Set them in your `vimrc` before the plugin loads.

```vim
" Prevent auto-activation on file open (use :MdRenderEnable manually)
let g:mdrender_enabled = 0

" Disable specific elements
let g:mdrender_elements = {'tables': v:false, 'hr': v:false, 'tasks': v:false}

" Bullet characters per indent depth
let g:mdrender_bullet_chars = ['•', '◦', '▪']

" Debounce delay in milliseconds before re-rendering after keystrokes
let g:mdrender_debounce_ms = 150

" Skip files larger than this many bytes (default: 200 KiB)
let g:mdrender_max_file_size = 204800

" Keep cursor line concealed (default: cursor line reveals raw source)
let g:mdrender_cursor_reveal = 0
```

### Themes

Control the colour scheme for all `MdXxx` highlight groups with `g:mdrender_theme`.

**Built-in themes:**

| Name | Description |
|:-----|:------------|
| `'auto'` | *(default)* Each group links to a colorscheme semantic group (`Title`, `Statement`, …) and adapts to whatever theme is active |
| `'dark'` | Opinionated dark palette (One Dark-inspired). Best with `termguicolors` and a dark background |
| `'light'` | Opinionated light palette (GitHub-inspired). Best with `termguicolors` and a light background |
| `'minimal'` | Style-only — no colour at all. Heading levels are distinguished by bold/italic/underline combinations |

```vim
let g:mdrender_theme = 'dark'
```

**User theme files:**

Any name that is not a built-in triggers a file search across `runtimepath`.
Create `mdrender/themes/<name>.vim` anywhere on your runtimepath and assign the
palette to `g:mdrender_theme_def`:

```vim
" ~/.config/vim/mdrender/themes/ocean.vim
let g:mdrender_theme_def = {
\   'MdH1': 'guifg=#96cbfe gui=bold ctermfg=75 cterm=bold',
\   'MdH2': 'guifg=#7ec8e3 gui=bold ctermfg=74 cterm=bold',
\   'MdH3': 'guifg=#99d1f5 gui=bold ctermfg=117 cterm=bold',
\ }
```

```vim
" vimrc
let g:mdrender_theme = 'ocean'
```

Only the groups you specify are overridden — absent groups fall through to the
`'auto'` colorscheme links. Third-party plugins can ship themes the same way.

**Inline dict:**

Pass the palette directly without a file:

```vim
let g:mdrender_theme = {
\   'MdH1': 'guifg=#ff6688 gui=bold ctermfg=210 cterm=bold',
\   'MdH2': 'guifg=#ffaa33 gui=bold ctermfg=215 cterm=bold',
\ }
```

**Per-group overrides** always win over any theme — place them in a `ColorScheme`
autocmd so they survive theme switches:

```vim
autocmd ColorScheme * hi MdH1 guifg=#ff0000 gui=bold
```

To reload the theme after changing `g:mdrender_theme` at runtime:

```vim
:doautocmd ColorScheme
```

## Highlight groups

In `'auto'` mode (the default), all groups link to standard Vim semantic groups
and adapt automatically to your colorscheme. Named or file-based themes replace
those links with fixed colours or styles.

Override any individual group after your colorscheme loads:

```vim
autocmd ColorScheme * hi MdH1 guifg=#ff6688 gui=bold
```

| Group | Default link | Element |
|:------|:-------------|:--------|
| `MdH1` | `Title` | Heading 1 |
| `MdH2` | `Statement` | Heading 2 |
| `MdH3` | `Type` | Heading 3 |
| `MdH4` | `Special` | Heading 4 |
| `MdH5` | `Identifier` | Heading 5 |
| `MdH6` | `Comment` | Heading 6 |
| `MdBold` | *(bold only)* | `**bold**` |
| `MdItalic` | *(italic only)* | `*italic*` |
| `MdBoldItalic` | *(bold + italic)* | `***bold italic***` |
| `MdStrike` | *(strikethrough)* | `~~strike~~` |
| `MdCodeInline` | `String` | `` `code` `` |
| `MdCodeBlock` | `CursorLine` | Fenced code block background |
| `MdLink` | `Underlined` | `[label](url)` |
| `MdTaskTodo` | `Todo` | `- [ ]` |
| `MdTaskDone` | `Comment` | `- [x]` |
| `MdHRule` | `NonText` | `---` horizontal rule |
| `MdListBullet` | `Special` | Bullet characters |
| `MdTableHeader` | `Statement` | Table header row |
| `MdTableBorder` | `NonText` | Table separator row |

## Documentation

Full documentation is available inside Vim:

```vim
:help mdrender
```

## License

GPL v2
