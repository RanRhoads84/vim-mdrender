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
Plug 'username/vim-mdrender'
```

### Vim built-in packages

```sh
git clone https://github.com/username/vim-mdrender \
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

All variables are optional.
Set them in your `vimrc` before the plugin loads.

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

## Highlight groups

All groups link to standard Vim semantic groups and adapt automatically to your colorscheme.
Override them after your colorscheme loads:

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
