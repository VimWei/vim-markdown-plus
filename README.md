# vim-markdown-plus

**Enhanced Markdown editing for Vim.**

This plugin complements [vim-markdown](https://github.com/tpope/vim-markdown) and [wiki.vim](https://github.com/lervag/wiki.vim), providing advanced Markdown editing features. It is designed for seamless integration and a consistent, efficient workflow.

## Features
- Work alongside tpope/vim-markdown and lervag/wiki.vim
- Smart toggling Bold, Italic, Strike and inline Code
- Smart toggling markdown URL Link, Image Link and custom File Link
- Smart toggling Todo checkbox markers to reflect task status
- Smart toggling Code Block and Quote Block
- Smart toggling gq format
- Smart list symbol conversion and deletion
- Syntax: Conceal markdown link and fix todo list checkbox

## Installation

* **With vim-plug:**
```vim
Plug 'VimWei/vim-markdown-plus'
```

* **Or with Vim built-in packages:**
```sh
mkdir -p ~/.vim/pack/markdown/start
cd ~/.vim/pack/markdown/start
git clone https://github.com/VimWei/vim-markdown-plus.git
```

## Quick Guide

For **detailed usage, all mappings, and advanced features**, please see the in-plugin documentation:

```
:help markdown-plus
```

## Acknowledgements

* lervag/wiki.vim:

The Link Management features in this project directly call several functions from wiki.vim. Additionally, many ideas and technical solutions were inspired by discussions with Lervåg regarding specific implementation details.

* ubaldot/vim-markdown-extras:

The Text Formatting features in this project utilize selected functions from vim-markdown-extras. This project includes components licensed under the BSD 3-Clause License, © 2025 Ubaldo Tiberi. See LICENSE.bsd for details.

---

Contributions and feedback are welcome!
