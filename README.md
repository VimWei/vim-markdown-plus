# vim-markdown-plus

## Description

This plugin enhances Markdown editing in Vim by providing essential tools missing from tpope/vim-markdown and lervag/wiki.vim. It features intuitive text styling, code block formatting, checkbox toggling, link and list management, and more—all designed for an efficient, seamless workflow with smart, context-aware mappings that naturally extend Vim-markdown.

## Features

- **Smart Text Styling:** Intelligently toggle **bold**, *italic*, ~~strikethrough~~, and `inline code`. The same mapping adds or removes styling. Works with motions!
- **Code Block Formatting:** Quickly wrap selections in code blocks with language specifiers.
- **Advanced Checkbox/Todo Management:** Quickly add, remove, or update checkboxes and task states with intuitive mappings.
- **Smart Link & Image Toggling:** Instantly add or remove Markdown links (`[text](url)`) and image links (`![alt](url)`) with a single mapping—works as an operator, in visual mode, or on the word under the cursor. Also supports unwrapping links to plain URLs.
- **Seamless List Formatting:** New empty buffers are automatically set to the markdown filetype, enabling instant use of Vim's `gq` formatting for lists and paragraphs. Includes an `:UngqFormat` command to restore original formatting if needed.

## Mappings

All mappings are prefixed with `<leader>m`.

### Text Formatting

These mappings work in Normal, Visual, and Operator-pending modes.

- `<leader>mb`: Toggle **bold**.
- `<leader>mi`: Toggle *italic*.
- `<leader>ms`: Toggle ~~strikethrough~~.
- `<leader>mc`: Toggle `inline code`.

**Smart Behavior:**
- In Visual mode, wraps the selection.
- As an operator (`<leader>mb{motion}`), wraps the text covered by the motion.
- In Normal mode on a word, wraps the word.
- In Normal mode inside a styled block, removes the styling from the entire block.

### Code Blocks

- `<leader>mcb` (Normal/Visual): Wrap the current line or selected lines in a fenced code block.
- `:WrapInCodeBlock` [range]: Command to wrap the given line range in a code block.

### Checkboxes / Task Lists

- `<leader>mtd`: Add or remove a checkbox `[ ]` on the current line.
- `<leader>mdd`: Toggle between `[ ]` (pending) and `[x]` (done).
- `<leader>mdr`: Toggle between `[ ]` (pending) and `[-]` (rejected/wontfix).
- `<leader>mdi`: Increase maturity: `[ ]` → `[.]` → `[o]` → `[x]`.
- `<leader>mdp`: Decrease maturity: `[x]` → `[o]` → `[.]` → `[ ]`.

### Link Management

- `<leader>mll`: Smartly toggle a regular Markdown link (`[text](url)`).
  - In Normal mode: acts as an operator, so you can use motions (e.g. `<leader>mlliw`).
  - In Visual mode: applies to the selection.
  - If not a link, creates one (prompts for URL if needed); if already a link, removes the link wrapper, keeping the text.
- `<leader>mpp`: Smartly toggle an image link (`![alt](url)`).
  - Usage同上，支持操作符、可视、普通模式。
  - 若不是图片链接则创建，若已有则移除。
- `<leader>mlu`: Unwrap a Markdown link, leaving only the URL as plain text (`[text](url)` → `url`).

### List Formatting

- `gq` (Normal/Visual): Format lists and paragraphs using Vim's built-in formatting commands. This works instantly in new empty buffers because their filetype is set to markdown automatically.
- `:UngqFormat` [range]: Restore the original formatting of lines that were previously formatted with `gq`.

## Installation

Install using your favorite package manager, such as vim-plug

```
Plug 'VimWei/vim-markdown-plus'
```

or use Vim's built-in package support:

```
mkdir -p ~/.vim/pack/markdown/start
cd ~/.vim/pack/mardown/start
git clone https://github.com/VimWei/vim-markdown-plus.git
```

## Usage

Open a markdown file and use the mappings above. For more detailed information and configuration options, see `:h markdown-plus`.
