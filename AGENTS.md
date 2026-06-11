# AGENTS.md

## Repo facts
- **Vim plugin** (`vim-markdown-plus`) — enhanced Markdown editing for Vim
- **Vim9 script only** — every `.vim` file starts with `vim9script`; use Vim9 syntax (not legacy VimL)
- **Min Vim version**: 9.1.1270 (strict check on Win32 in `plugin/markdown_plus.vim:14`)
- **Has CI** via `.github/workflows/tests.yml` (ubuntu/windows/macos, Vim v9.1.1270). Test guide in `doc/TESTING.md`, implementation plan in `doc/TestingPlan.md`.
- **Remote**: `git@github.com:VimWei/vim-markdown-plus.git`

## Directory layout
| Path | Role |
|---|---|
| `plugin/markdown_plus.vim` | Plugin entrypoint; guard `g:loaded_markdown_plus`, sets filetype autocmd |
| `ftplugin/markdown.vim` | All `<localleader>` key mappings for markdown buffers |
| `autoload/mplus.vim` | Top-level autoload; `CheckAndSetFiletype()` |
| `autoload/mplus/*.vim` | Core modules: `text`, `link`, `todo`, `code`, `quote`, `list`, `llmclean`, `gqformat`, `snippets`, `constants`, `utils` |
| `after/syntax/*.vim` | Syntax overrides (markdown, powershell, ps1, ps1-patch, sh) |
| `doc/markdown_plus.txt` | Help doc (`:help markdown-plus`) |

## External dependencies (runtime, not packaged)
- **wiki.vim** (`lervag/wiki.vim`) — `mplus/link.vim` calls `wiki#link#*` functions directly
- **vim-quickui** (`skywind3000/vim-quickui`) — `mplus/llmclean.vim` uses quickui for UI dialogs

## Conventions
- All mappings use `<localleader>` by default, overridable via `g:markdown_leader`
- Mappings are buffer-local (`<buffer>`) and scoped to markdown filetype
- Uses `<Plug>` mappings with `hasmapto()` / `mapcheck()` guards to avoid conflicts
- Todo commands are defined as `-range` Ex commands (e.g. `:TodoCheckboxToggle`)
- List symbol commands use `-nargs=1` (e.g. `:ListSymbol *`)

## Testing
- **Test directory**: `test/` with subdirectories per module (`test-text/`, `test-todo/`, `test-list/`)
- **Init file**: `test/init.vim` sets up runtimepath and basic options for all tests
- **Runners**: `make test` (from `test/`, Linux/macOS/Git Bash), `.\run-tests.ps1` (PowerShell, from `test/`), `run-tests.cmd` (CMD)
- **Single test**: `vim -es -u test/test-text/test-surround-simple.vim +qall` (run from plugin root)
- **Single group**: `make -C test test-text` or `.\run-tests.ps1 -Group test-text`
- **Structure**: each test group has its own `Makefile`; test files use `vim9script`, source `../init.vim`, import autoload modules, call test functions directly, report via `v:errors`
- **Rules**: pure Vim9 script, no test framework, built-in `assert_*`, each test function independent
- **Test groups implemented**:
  - `test-text/`: `test-surround-simple.vim` — bold, italic, strike, mark, code surround; single/multi-line; CJK, emoji, mixed ASCII/CJK
  - `test-todo/`: `test-checkbox-toggle.vim`, `test-done-toggle.vim`, `test-maturity.vim` — checkbox toggle, done state, maturity levels
  - `test-list/`: `test-change-symbol.vim` — symbol change, delete, numeric/alpha lists, CJK, GetListSymbols, GetListPattern
  - `test-utils/`: `test-is-in-range.vim`, `test-comparison.vim` — IsLess/IsGreater/IsEqual comparison functions
  - `test-code/`: `test-codeblock.vim` — UnsetBlock single/multi/CJK/partial/indented/overlapping
  - `test-quote/`: `test-quoteblock.vim` — set/unset/toggle quote blocks; CJK, expand, edge cases
  - `test-link/`: `test-toggle-link.vim` — wiki.vim dependency loading, ToggleLink/RemoveTextOnly basic calls
  - `test-gqformat/`: `test-ungq.vim` — UngqFormat paragraph/list/CJK/space handling
  - `test-llmclean/`: `test-llmclean.vim` — quickui dependency loading, ESC cancel, buffer initialization
  - `test-constants/`: `test-constants.vim` — TEXT_STYLES_DICT, CODEBLOCK_DICT, URL_PREFIXES structure validation
- **Must test CJK/multibyte** for all position-calculation functions
- **wiki.vim dependency** in `mplus/link.vim`: skip if absent or mock `wiki#link#*` functions
- **CI**: matrix on ubuntu/windows/macos, uses `rhysd/action-setup-vim` with Vim v9.1.1270. Installs wiki.vim and vim-quickui dependencies.
