# vim-markdown-plus 测试计划

> 本文档记录测试体系构建的进度与后续计划。
> 测试规范遵循 `doc/TESTING.md` 和 `doc/multibyte-handling-summary.md`。

## 进度总览

| 阶段 | 测试组 | 状态 | 文件数 | 测试数 |
|------|--------|------|--------|--------|
| 阶段 1 | 基础设施 | ✅ 完成 | 6 | - |
| 阶段 2.1 | test-text | ✅ 完成 | 1 | 14 |
| 阶段 2.2 | test-todo | ✅ 完成 | 3 | 30 |
| 阶段 2.3 | test-list | ✅ 完成 | 1 | 14 |
| 阶段 2.4 | test-utils | ✅ 完成 | 2 | 14 |
| 阶段 3.1 | test-code | ✅ 完成 | 1 | 13 |
| 阶段 3.2 | test-quote | ✅ 完成 | 1 | 18 |
| 阶段 3.3 | test-link | ✅ 完成 | 1 | 5 |
| 阶段 4.1 | test-gqformat | ✅ 完成 | 1 | 15 |
| 阶段 4.2 | test-llmclean | ✅ 完成 | 1 | 13 |
| 阶段 4.3 | test-constants | ✅ 完成 | 1 | 4 |
| 阶段 5 | CI 集成 | ✅ 完成 | 1 | - |

---

## 已完成

### 阶段 1：基础设施

| 文件 | 说明 |
|------|------|
| `test/init.vim` | 公共初始化（runtimepath、noswapfile、nomore、hidden、依赖加载） |
| `test/Makefile` | GNU Make 顶层运行器 |
| `test/run-tests.ps1` | PowerShell 运行脚本 |
| `test/run-tests.cmd` | CMD 运行脚本（调用 PowerShell） |

### 阶段 2.1：test-text/（文本样式测试）

**文件**: `test/test-text/test-surround-simple.vim`（14 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_bold_single_line` | Bold 单行 |
| `Test_italic_single_line` | Italic 单行 |
| `Test_strike_single_line` | Strike 单行 |
| `Test_mark_single_line` | Mark 单行 |
| `Test_code_single_line` | Code 单行 |
| `Test_bold_multi_line` | Bold 多行 |
| `Test_italic_multi_line` | Italic 多行 |
| `Test_bold_cjk` | CJK Bold |
| `Test_italic_cjk` | CJK Italic |
| `Test_cjk_multi_line` | CJK 多行 |
| `Test_ascii_cjk_mixed` | ASCII + 中文混合 |
| `Test_cjk_ascii_leading` | 中文 + ASCII 混合 |
| `Test_bold_emoji` | Emoji 单字符 |
| `Test_single_char` | 单字符选择 |

### 阶段 2.2：test-todo/（Todo checkbox 测试）

| 文件 | 测试数 | 覆盖函数 |
|------|--------|---------|
| `test-checkbox-toggle.vim` | 9 | `CheckboxToggle` |
| `test-done-toggle.vim` | 8 | `DoneToggle` |
| `test-maturity.vim` | 13 | `MaturityNext`, `MaturityPrevious` |

### 阶段 2.3：test-list/（列表符号转换测试）

**文件**: `test/test-list/test-change-symbol.vim`（14 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_change_symbol_hyphen_to_star` | `-` → `*` |
| `Test_change_symbol_star_to_plus` | `*` → `+` |
| `Test_change_symbol_to_number` | `-` → `1.` |
| `Test_change_symbol_to_alpha` | `-` → `a.` |
| `Test_change_symbol_delete` | 删除符号 `d` |
| `Test_change_symbol_non_list` | 非列表行添加符号 |
| `Test_change_symbol_indented` | 缩进列表项 |
| `Test_change_symbol_multiple_lines` | 多行批量转换 |
| `Test_change_symbol_cjk` | CJK 文本列表 |
| `Test_get_list_symbols` | `GetListSymbols()` |
| `Test_get_list_pattern` | `GetListPattern()` |
| `Test_change_symbol_delete_indented` | 删除缩进列表符号 |
| `Test_change_symbol_preserves_content` | 保留内容格式 |
| `Test_change_symbol_numeric_to_star` | 数字列表转星号 |

### 阶段 2.4：test-utils/（工具函数测试）

**文件 1**: `test/test-utils/test-is-in-range.vim`（3 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_is_less_basic` | 基本字典序比较 |
| `Test_is_greater_basic` | 基本字典序比较 |
| `Test_is_equal_basic` | 相等比较 |

**文件 2**: `test/test-utils/test-comparison.vim`（11 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_is_less_basic` | 基本字典序比较 |
| `Test_is_less_different_length` | 不同长度列表比较 |
| `Test_is_greater_basic` | 基本字典序比较 |
| `Test_is_equal_basic` | 相等比较 |
| `Test_is_equal_different_length` | 前缀相等 |
| `Test_is_less_equal_elements` | 相等元素边界 |
| `Test_is_less_single_element` | 单元素比较 |
| `Test_is_greater_single_element` | 单元素比较 |
| `Test_is_equal_single_element` | 单元素相等 |
| `Test_is_less_with_zeros` | 含零值比较 |
| `Test_is_greater_with_zeros` | 含零值比较 |

**注意**: `IsInRange()` 测试需要语法高亮支持（`synID()`），在 Vim 的 `-es` 模式下无法正确加载 syntax 文件。当前只测试 `IsLess`/`IsGreater`/`IsEqual` 比较函数。

### 阶段 3.1：test-code/（代码块测试）

**文件**: `test/test-code/test-codeblock.vim`（13 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_unset_codeblock_single` | 移除单个代码块 |
| `Test_unset_codeblock_cjk` | CJK 内容代码块 |
| `Test_unset_codeblock_multiple` | 多个代码块移除 |
| `Test_unset_codeblock_partial_middle` | 部分选中（代码块中间） |
| `Test_unset_codeblock_from_open_wrapper` | 从开包裹行开始选中 |
| `Test_unset_codeblock_to_close_wrapper` | 到闭包裹行结束选中 |
| `Test_unset_codeblock_close_wrapper_only` | 仅选中闭包裹行 |
| `Test_unset_codeblock_open_wrapper_only` | 仅选中开包裹行 |
| `Test_unset_codeblock_indented` | 缩进代码块（正则不匹配） |
| `Test_unset_codeblock_no_codeblock` | 非代码块行（无变化） |
| `Test_unset_codeblock_cjk_wrapper` | CJK 语言标签 |
| `Test_unset_codeblock_overlapping` | 重叠选中多个代码块 |
| `Test_unset_codeblock_at_bof` | 文件开头的代码块 |

**注意**: `SetBlock()` 使用 `input()` 交互，测试时需 mock 或跳过。`ToggleCodeBlock()` 依赖语法高亮。当前只测试 `UnsetBlock()`。

### 阶段 3.2：test-quote/（引用块测试）

**文件**: `test/test-quote/test-quoteblock.vim`（18 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_set_quote_single` | 单行添加引用 |
| `Test_set_quote_multiple` | 多行添加引用 |
| `Test_set_quote_cjk` | CJK 内容添加引用 |
| `Test_set_quote_empty_lines` | 空行添加引用 |
| `Test_set_quote_partial_range` | 部分范围添加引用 |
| `Test_unset_quote_single` | 单行移除引用 |
| `Test_unset_quote_multiple` | 多行移除引用 |
| `Test_unset_quote_expand_up` | 向上扩展找到引用开始 |
| `Test_unset_quote_expand_down` | 向下扩展找到引用结束 |
| `Test_unset_quote_expand_both` | 双向扩展 |
| `Test_unset_quote_cjk` | CJK 内容移除引用 |
| `Test_unset_quote_varying_formats` | 不同引用格式 |
| `Test_unset_quote_non_quote_lines` | 非引用行（无变化） |
| `Test_toggle_quote_set` | Toggle 设置引用 |
| `Test_toggle_quote_unset` | Toggle 移除引用 |
| `Test_toggle_quote_mixed` | Toggle 混合内容 |
| `Test_set_quote_at_eof` | 文件末尾添加引用 |
| `Test_unset_quote_at_bof` | 文件开头移除引用 |

**注意**: 引用检测使用正则 `^\s*>\s`，不依赖语法高亮。

### 阶段 3.3：test-link/（链接测试）

**文件**: `test/test-link/test-toggle-link.vim`（5 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_wiki_vim_loaded` | 验证 wiki.vim 已加载 |
| `Test_wiki_link_get_all_from_range` | wiki#link#get_all_from_range 查找链接 |
| `Test_toggle_link_basic_call` | ToggleLink 基本调用（wiki 链接） |
| `Test_remove_text_only_basic` | RemoveTextOnly 基本调用 |
| `Test_toggle_link_cjk_basic` | CJK 内容链接 |

**依赖处理**: `link.vim` 依赖 `wiki.vim`（`lervag/wiki.vim`）。已在 `test/init.vim` 中配置自动加载：
- 检测 `$HOME/vimfiles/plugged/wiki.vim` 目录
- 添加到 runtimepath
- 显式 source plugin/wiki.vim（因为测试使用 `--noplugin`）

**注意**: wiki.vim 需要配置 wiki root 才能完整测试链接创建功能。当前测试验证依赖加载和基本调用不崩溃。

### 阶段 4.1：test-gqformat/（格式测试）

**文件**: `test/test-gqformat/test-ungq.vim`（15 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_ungq_single_paragraph` | 单段落合并 |
| `Test_ungq_multiple_paragraphs` | 多段落合并（空行分隔） |
| `Test_ungq_list_item` | 列表项合并（短横线） |
| `Test_ungq_multiple_list_items` | 多个列表项合并 |
| `Test_ungq_cjk_no_space` | CJK 字符间无空格 |
| `Test_ungq_ascii_space` | ASCII 字符间加空格 |
| `Test_ungq_mixed_cjk_ascii` | CJK + ASCII 混合边界 |
| `Test_ungq_full_buffer` | 全缓冲区范围 |
| `Test_ungq_partial_buffer` | 部分缓冲区范围 |
| `Test_ungq_numbered_list` | 数字列表合并 |
| `Test_ungq_alpha_list` | 字母列表合并 |
| `Test_ungq_star_list` | 星号列表合并 |
| `Test_ungq_hash_list` | 井号列表合并 |
| `Test_ungq_cjk_punctuation` | CJK 标点无空格 |
| `Test_ungq_paragraph_then_list` | 段落后接列表 |

**注意**: `UngqFormat()` 是 legacy Vim script 函数（`function!`），测试文件使用 `vim9script` 调用。部分范围处理会改变总行数（删除原行后插入合并行）。

### 阶段 4.2：test-llmclean/（AI 清理测试）

**文件**: `test/test-llmclean/test-llmclean.vim`（13 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_quickui_loaded` | 验证 vim-quickui 已加载 |
| `Test_llmclean_import` | 验证 llmclean 模块可导入 |
| `Test_llmclean_cancel` | ESC 取消操作 |
| `Test_llmclean_no_ops` | 无操作执行 |
| `Test_llmclean_empty_buffer` | 空缓冲区处理 |
| `Test_llmclean_cjk_content` | CJK 内容处理 |
| `Test_llmclean_codeblock` | 代码块处理 |
| `Test_llmclean_numbered_list` | 数字列表处理 |
| `Test_llmclean_chinese_punct_spaces` | 中文标点空格 |
| `Test_llmclean_citations` | 引用标记处理 |
| `Test_llmclean_headings` | 标题处理 |
| `Test_llmclean_backslash_numbered` | 数字列表反斜杠 |
| `Test_llmclean_redundant_spaces` | 列表冗余空格 |

**依赖处理**: `llmclean.vim` 依赖 `vim-quickui`（`skywind3000/vim-quickui`）。已在 `test/init.vim` 中配置自动加载：
- 检测 `$HOME/vimfiles/plugged/vim-quickui` 目录
- 添加到 runtimepath
- 显式 source plugin/quickui.vim（因为测试使用 `--noplugin`）

**测试方法**: 使用 `feedkeys()` 模拟用户输入（参考 vim/vim 和 vim-quickui 的测试方法）。当前测试主要验证：
- 依赖加载和模块导入
- ESC 取消操作（内容不变）
- 各种缓冲区设置的正确初始化

**注意**: `llmclean.vim` 的内部函数（`DeleteLinesMatching`、`AddEmptyLineAfterHeadings` 等）是非导出的，只能通过公共 API `Run()` 测试。`Run()` 使用 `quickui#dialog#open` 进行交互式对话框，在测试环境中使用 `feedkeys("\<ESC>", 't')` 模拟取消操作。完整的功能测试需要模拟复杂的键盘导航（Tab/Enter 选择按钮），这在实际测试中较为困难。

### 阶段 4.3：test-constants/（常量验证测试）

**文件**: `test/test-constants/test-constants.vim`（4 个测试）

| 测试函数 | 覆盖场景 |
|---------|---------|
| `Test_text_styles_dict_structure` | `TEXT_STYLES_DICT` 结构完整性：9 个样式键全部存在，每个条目含 open_delim/close_delim/open_regex/close_regex 且非空 |
| `Test_text_styles_dict_delimiters_match_regex` | 每个样式的 open_delim 能被 open_regex 匹配，close_delim 能被 close_regex 匹配 |
| `Test_codeblock_dict` | `CODEBLOCK_OPEN_DICT`/`CODEBLOCK_CLOSE_DICT` 结构与正则验证；`QUOTEBLOCK_OPEN_DICT` 基本验证 |
| `Test_url_prefixes` | `URL_PREFIXES` 列表包含 7 种常见协议，所有条目含 `://` |

### 阶段 5：CI 集成

**文件**: `.github/workflows/tests.yml`

**配置要点**:

| 项目 | 说明 |
|------|------|
| 触发条件 | `push` (main/master)、`pull_request` |
| 矩阵 | ubuntu-latest, windows-latest, macos-latest |
| Vim 版本 | v9.1.1270（`rhysd/action-setup-vim`） |
| 依赖安装 | 克隆 `wiki.vim` 和 `vim-quickui` 到 `$HOME/vimfiles/plugged/` |
| Linux/macOS | `make test` |
| Windows | `.\run-tests.ps1` |
| fail-fast | `false`（所有平台独立运行） |

---

## 测试规范提醒

编写新测试时必须遵循：

1. **规则 1**: 纯 Vim9 script，使用 `assert_*` 内置断言
2. **规则 2**: 每个测试函数独立（setup → execute → assert）
3. **规则 5**: 多字节字符测试必须使用 `setcharpos()` / `setcursorcharpos()`，参考 `doc/multibyte-handling-summary.md`
4. **规则 5.3**: 每个位置计算函数至少测试：纯 ASCII、ASCII+中文、中文+ASCII、Emoji
5. **规则 6**: 外部依赖在 `test/init.vim` 中配置加载，使用 `feedkeys()` 模拟交互
6. **规则 8**: 使用 `setcharpos()` 设置 marks，`setcursorcharpos()` 设置光标
7. **规则 9**: 注意 `setline` 清除 marks、`normal!` 限制、缓冲区清理

---

## 运行方式

```bash
# 运行所有测试
cd test && .\run-tests.ps1

# 运行单个测试组
cd test && .\run-tests.ps1 test-text

# 运行单个测试文件
vim -es -u test\test-text\test-surround-simple.vim +qall
```
