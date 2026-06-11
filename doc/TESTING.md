# vim-markdown-plus 测试指南

## 测试哲学

本项目的测试方案遵循三个原则：

1. **零依赖**：不引入任何第三方测试框架，只使用 Vim 内置的 `assert_*` 函数和 `v:errors` 机制。测试代码本身就是 Vim script，不需要额外安装或学习新语法。

2. **自包含**：每个测试文件自己就是完整的运行器，包含初始化、测试执行、结果报告的全部逻辑。不依赖外部运行器或框架。

3. **最小化工具链**：仅使用 Makefile（Linux/macOS）和 PowerShell 脚本（Windows）进行编排，不引入额外的测试运行工具。

### Vim 测试方案分类

Vim 插件的测试方案大致分两类：

第一类是第三方框架，代表是 vader.vim 和 vim-themis。vader.vim 是 junegunn（vim-plug 作者）做的，用自定义 DSL 写测试，语法是 Given/Do/Expect 三段式，简洁但要学一套新语法。vim-themis 是日本社区的主流，用原生 Vimscript 写，有独立的 themis CLI 命令，支持多种输出格式，功能更全但也更重。两者的共同点是引入了外部依赖。

第二类是自研轻量方案，vim/vim 官方仓库、vim-quickui、wiki.vim 都属于这一类。核心思路完全一样：用 Vim 内置的 assert_* 函数做断言，用 v:errors 收集错误，用 Makefile 编排运行，零外部依赖。区别只在实现细节上——vim/vim 官方搞了个集中的 runtest.vim 运行器，支持屏幕转储对比和测试过滤；vim-quickui 没有统一运行器，特色是用 feedkeys() 注入按键来模拟 UI 交互，分交互式和自动化两套测试；wiki.vim 最极简，每个测试文件自己就是运行器，末尾调一个 wiki#test#finished() 检查 v:errors 然后退出。

### 架构选择：分布式 + 函数包裹

本项目选择第二类方案。结合 Vim 官方仓库、vim-quickui 和 wiki.vim 的测试经验，具体采用如下混合模式：

| 维度 | 选择 | 理由 |
|------|------|------|
| 运行器 | 分布式（每个文件自运行） | 项目规模小，无需 `runtest.vim` 复杂性 |
| 测试结构 | 函数包裹 `Test_xxx()` | 未来可无缝迁移到集中式运行器 |
| 断言 | Vim 内置 `assert_*` | 零依赖，与 Vim 官方一致 |
| 编排 | Makefile + PowerShell 双轨 | 跨平台兼容（Linux/macOS/Windows） |

这种模式兼顾了 wiki.vim 的简单性、Vim 官方的可扩展性，以及 vim-quickui 的 feedkeys() 交互模拟技术。

## 目录结构

```
test/
├── Makefile              # 顶层测试运行器（Linux/macOS/Git Bash）
├── run-tests.ps1         # PowerShell 测试运行器（Windows）
├── run-tests.cmd         # CMD 测试运行器（Windows 备选）
├── init.vim              # 公共初始化（runtimepath、插件加载、依赖配置）
├── test-text/            # 文本样式测试（Bold/Italic/Strike/Mark/Code）
│   ├── Makefile
│   └── test-surround-simple.vim
├── test-todo/            # Todo checkbox 测试
│   ├── Makefile
│   ├── test-checkbox-toggle.vim
│   ├── test-done-toggle.vim
│   └── test-maturity.vim
├── test-list/            # 列表符号转换测试
│   ├── Makefile
│   └── test-change-symbol.vim
├── test-code/            # 代码块测试
│   ├── Makefile
│   └── test-codeblock.vim
├── test-quote/           # 引用块测试
│   ├── Makefile
│   └── test-quoteblock.vim
├── test-link/            # 链接测试（依赖 wiki.vim）
│   ├── Makefile
│   └── test-toggle-link.vim
├── test-gqformat/        # 格式测试
│   ├── Makefile
│   └── test-ungq.vim
├── test-llmclean/        # AI 清理测试（依赖 vim-quickui）
│   ├── Makefile
│   └── test-llmclean.vim
└── test-utils/           # 工具函数测试
    ├── Makefile
    ├── test-is-in-range.vim
    └── test-comparison.vim
```

## 核心机制

### 1. 运行方式

**Linux / macOS / Git Bash:**
```bash
# 运行所有测试
cd test && make test

# 运行单个测试组
cd test && make test-text

# 运行单个测试文件
vim -es -u test/test-text/test-surround-simple.vim +qall
```

**Windows PowerShell:**
```powershell
# 运行所有测试
cd test; .\run-tests.ps1

# 运行单个测试组
cd test; .\run-tests.ps1 test-text

# 运行单个测试文件
vim -es -u test\test-text\test-surround-simple.vim +qall
```

**Windows CMD:**
```cmd
cd test
run-tests.cmd
```

**清理测试产物:**
```bash
# 删除调试过程中产生的临时文件（*-errors.txt、error.log、test-output.txt 等）
cd test && make clean
```

### 2. 测试文件模板

```vim
vim9script

# 1. 加载公共配置
source ../init.vim

# 2. 加载被测模块
import autoload '../../autoload/mplus/text.vim' as text
import autoload '../../autoload/mplus/utils.vim' as utils

# 3. 准备测试环境
setlocal filetype=markdown
setlocal syntax=markdown

# 4. 编写测试用例（每个函数一个测试）
def Test_SurroundSimple_bold_single_line()
    # Setup: 设置缓冲区内容
    setline(1, 'Hello world')

    # Setup: 设置 marks 模拟 visual 选择（推荐直接设置字符位置）
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])

    # Execute: 调用被测函数
    text.SurroundSimple('markdownBold')

    # Assert: 检查结果
    assert_equal('**Hell**o world', getline(1))
enddef

def Test_RemoveSurrounding_bold()
    setline(1, '**Hello** world')
    cursor(1, 3)  # 光标放在 Hello 上
    text.RemoveSurrounding()
    assert_equal('Hello world', getline(1))
enddef

# 5. 运行所有测试并报告
Test_SurroundSimple_bold_single_line()
Test_RemoveSurrounding_bold()

# 检查 v:errors 并退出
if len(v:errors) > 0
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'All tests passed'
    quitall!
endif
```

### 3. Makefile 模板

**顶层 `test/Makefile`:**
```makefile
MYVIM ?= vim -es -T dumb --not-a-term --noplugin -n
MAKEFLAGS+=--no-print-directory

TESTS := $(wildcard test-*)

.PHONY: test clean $(TESTS)

test: $(TESTS)

$(TESTS):
	$(MAKE) -C $@

clean:
	find . \( -name '*-errors.txt' -o -name 'error.log' -o -name 'test-output.txt' -o -name 'import-*.txt' \) -delete
```

**子目录 `test/test-text/Makefile`:**
```makefile
MYVIM ?= vim -es -T dumb --not-a-term --noplugin -n

tests := $(wildcard test-*.vim)

.PHONY: all $(tests)

test: $(tests)

$(tests):
	@$(MYVIM) -u $@ +qall
```

### 4. Windows 兼容脚本

Makefile 依赖 GNU Make，Windows 默认没有。提供两套等效脚本：

**PowerShell `test/run-tests.ps1`:**
```powershell
param(
    [string]$Group  # 可选：指定测试组，如 "test-text"
)

$MYVIM = if (Get-Command nvim -ErrorAction SilentlyContinue) { "nvim" } else { "vim" }
$MYVIM_ARGS = "-es", "-T", "dumb", "--not-a-term", "--noplugin", "-n"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExitCode = 0

function Run-TestFile($vimFile) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($vimFile)
    Write-Host "  $name ... " -NoNewline
    $proc = Start-Process $MYVIM -ArgumentList @($MYVIM_ARGS, "-u", $vimFile, "+qall") -NoNewWindow -Wait -PassThru
    if ($proc.ExitCode -ne 0) {
        Write-Host "FAILED" -ForegroundColor Red
        return 1
    }
    Write-Host "OK" -ForegroundColor Green
    return 0
}

if ($Group) {
    # 运行指定测试组
    $groupDir = Join-Path $ScriptDir $Group
    if (!(Test-Path $groupDir)) {
        Write-Host "Test group not found: $Group" -ForegroundColor Red
        exit 1
    }
    Write-Host "Running: $Group"
    Get-ChildItem $groupDir -Filter "test-*.vim" | ForEach-Object {
        $ExitCode += Run-TestFile $_.FullName
    }
} else {
    # 运行所有测试组
    Write-Host "Running all tests"
    Get-ChildItem $ScriptDir -Directory -Filter "test-*" | ForEach-Object {
        Write-Host "Group: $($_.Name)"
        Get-ChildItem $_.FullName -Filter "test-*.vim" | ForEach-Object {
            $ExitCode += Run-TestFile $_.FullName
        }
    }
}

if ($ExitCode -gt 0) {
    Write-Host "`n$ExitCode test(s) failed" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nAll tests passed" -ForegroundColor Green
    exit 0
}
```

**CMD `test/run-tests.cmd`:**
```cmd
@echo off
setlocal
set MYVIM=vim
set MYVIM_ARGS=-es -T dumb --not-a-term --noplugin -n
set EXIT_CODE=0

for /d %%D in (test-*) do (
    echo Group: %%D
    for %%F in (%%D\test-*.vim) do (
        echo   %%~nF ...
        %MYVIM% %MYVIM_ARGS% -u "%%F" +qall
        if errorlevel 1 (
            echo     FAILED
            set /a EXIT_CODE+=1
        ) else (
            echo     OK
        )
    )
)

if %EXIT_CODE% gtr 0 (
    echo %EXIT_CODE% test(s) failed
    exit /b 1
) else (
    echo All tests passed
    exit /b 0
)
```

### 5. 公共初始化 `test/init.vim`

```vim
set nocompatible
let &runtimepath = simplify(fnamemodify(expand('<sfile>'), ':h') . '/..') . ',' . &runtimepath
set noswapfile
set nomore
set hidden

" 确保 markdown 语法可用
runtime! syntax/markdown.vim

" 添加 wiki.vim 依赖（如果存在）
let s:wiki_path = expand('$HOME/vimfiles/plugged/wiki.vim')
if isdirectory(s:wiki_path)
    let &runtimepath .= ',' . s:wiki_path
    " 由于测试使用 --noplugin，需要显式加载 wiki.vim
    execute 'source ' . s:wiki_path . '/plugin/wiki.vim'
endif

" 添加 vim-quickui 依赖（如果存在）
let s:quickui_path = expand('$HOME/vimfiles/plugged/vim-quickui')
if isdirectory(s:quickui_path)
    let &runtimepath .= ',' . s:quickui_path
    " 由于测试使用 --noplugin，需要显式加载 vim-quickui
    execute 'source ' . s:quickui_path . '/plugin/quickui.vim'
endif
```

**说明**：
- 测试使用 `--noplugin` 启动，插件不会自动加载
- 需要显式 `source` 插件文件来加载依赖
- 使用 `isdirectory()` 检测依赖是否存在，避免硬编码路径
- 依赖路径假设使用 vim-plug 安装到 `$HOME/vimfiles/plugged/`

## AI 测试编写指南

当使用 AI（如 Claude、OpenCode 等）编写测试时，请遵循以下规则：

### 规则 1: 纯 Vim9 Script

测试文件必须使用 `vim9script`，不使用任何第三方测试框架。断言使用 Vim 内置的 `assert_*` 函数族。

### 规则 2: 每个测试函数独立

每个测试函数应该：
1. 清理/设置缓冲区状态
2. 使用 `setcharpos()` 设置 marks（推荐）或 `normal!` 模拟 visual 选择
3. 使用 `setcursorcharpos()` 设置光标位置
4. 调用被测函数
5. 断言结果（文本内容、光标位置、marks 等）

```vim
def Test_FunctionName_scenario()
    # Setup
    setline(1, 'input text')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])

    # Execute
    mplus#module#FunctionName(args)

    # Assert
    assert_equal('expected output', getline(1))
enddef
```

### 规则 3: 测试优先级

按以下优先级编写测试：

**P0 - 核心功能（必须测试）:**
- `mplus/text.vim`: `SurroundSimple`, `SurroundSmart`, `RemoveSurrounding`
- `mplus/todo.vim`: `CheckboxToggle`, `DoneToggle`
- `mplus/list.vim`: `ChangeSymbol`
- `mplus/utils.vim`: `IsInRange`

**P1 - 重要功能（应该测试）:**
- `mplus/code.vim`: `ToggleCodeBlock`, `UnsetBlock`
- `mplus/quote.vim`: `ToggleQuoteBlock`
- `mplus/link.vim`: `ToggleLink`（需要 wiki.vim 依赖，可 mock）

**P2 - 辅助功能（可选测试）:**
- `mplus/gqformat.vim`: `UngqFormat`
- `mplus/llmclean.vim`: AI 清理功能
- `mplus/constants.vim`: 常量验证

### 规则 4: 测试场景覆盖

每个函数至少覆盖以下场景：

```vim
# 以 SurroundSimple 为例
def Test_SurroundSimple_single_line()     # 单行选择
def Test_SurroundSimple_multi_line()      # 多行选择
def Test_SurroundSimple_multibyte()       # 多字节字符（中文/日文）
def Test_SurroundSimple_empty_selection() # 空选择
```

### 规则 5: 多字节字符测试

**强制遵循 `doc/multibyte-handling-summary.md`**（以下简称"多字节规范"）。测试前务必先阅读该文档。

要点速查：
- 统一使用字符级 API：`setcharpos()`、`getcharpos()`、`charcol()`、`setcursorcharpos()`、`strchars()`、`strcharpart()`
- `getcharpos()`/`setcharpos()` 为 **1-based**；`strcharpart()` 为 **0-based**，需减 1 转换
- 每个涉及位置计算的函数至少测试：纯 ASCII、ASCII+中文、中文+ASCII、Emoji 混合

### 规则 6: 依赖处理

本项目部分模块依赖外部插件。测试时需要在 `test/init.vim` 中配置依赖加载。

#### 6.1 依赖加载配置

在 `test/init.vim` 中添加依赖检测和加载：

```vim
" 添加 wiki.vim 依赖（如果存在）
let s:wiki_path = expand('$HOME/vimfiles/plugged/wiki.vim')
if isdirectory(s:wiki_path)
    let &runtimepath .= ',' . s:wiki_path
    " 由于测试使用 --noplugin，需要显式加载插件
    execute 'source ' . s:wiki_path . '/plugin/wiki.vim'
endif

" 添加 vim-quickui 依赖（如果存在）
let s:quickui_path = expand('$HOME/vimfiles/plugged/vim-quickui')
if isdirectory(s:quickui_path)
    let &runtimepath .= ',' . s:quickui_path
    execute 'source ' . s:quickui_path . '/plugin/quickui.vim'
endif
```

**关键点**：
- 使用 `--noplugin` 启动测试时，插件不会自动加载
- 需要显式 `source` 插件文件
- 使用 `isdirectory()` 检测依赖是否存在，避免硬编码路径

#### 6.2 验证依赖加载

在测试中验证依赖是否正确加载：

```vim
def Test_wiki_vim_loaded()
    assert_true(exists('g:wiki_loaded'), 'wiki.vim should be loaded')
enddef

def Test_quickui_loaded()
    assert_true(exists('g:quickui_version'), 'vim-quickui should be loaded')
enddef
```

#### 6.3 测试交互式对话框（feedkeys 方法）

对于使用 `quickui#dialog#open` 等交互式对话框的函数，使用 `feedkeys()` 模拟用户输入：

```vim
# 模拟 ESC 取消操作
feedkeys("\<ESC>", 't')
llmclean.Run(1, line('$'))

# 模拟 Enter 确认
feedkeys("\<CR>", 't')
llmclean.Run(1, line('$'))
```

**参考**：vim/vim 官方测试和 vim-quickui 的 headless 测试均使用此方法。

#### 6.4 测试非导出函数

Vim9 script 的封装性很重要，不应为了测试而将函数改为 `export def`。正确做法是通过公共 API 测试：

```vim
# 错误：不要为了测试而修改模块
export def DeleteLinesMatching(...)  # 破坏封装性

# 正确：通过公共 API 测试
def Test_delete_dash_lines()
    setline(1, ['Content above.', '---', 'Content below.'])

    # 使用 feedkeys 模拟用户操作
    feedkeys("\<ESC>", 't')
    llmclean.Run(1, line('$'))

    # 验证结果
    assert_equal(2, line('$'))
enddef
```

#### 6.5 依赖缺失时的处理

如果依赖不存在，测试应该优雅地跳过或降级：

```vim
# 策略 A：跳过测试
if !exists('g:wiki_loaded')
    echo 'Skipping: wiki.vim not loaded'
    quitall!
endif

# 策略 B：只测试不依赖部分
def Test_module_import()
    # 即使依赖不存在，模块导入也应该成功
    assert_true(exists('*llmclean.Run'), 'llmclean.Run should exist')
enddef
```

### 规则 7: 断言风格

使用 Vim 内置断言，保持简洁：

```vim
# 文本断言
assert_equal('expected', getline(1))
assert_equal('expected', getline(1, 3))  # 多行

# 位置断言
assert_equal([1, 5], getcursorcharpos()[1:2])

# 布尔断言
assert_true(empty(result))
assert_false(found)

# 自定义错误消息
assert_report('Custom error: ' .. string(actual))
```

### 规则 8: Vim 状态模拟指南

本插件大量依赖 Vim 内部状态（marks、cursor、visual selection）。AI 编写测试时必须注意：

#### 8.1 模拟 Visual Selection

插件函数通常读取 `'[` 和 `']` marks（上次 visual 选择的范围）：

```vim
def Test_visual_selection()
    setline(1, 'Hello world')
    # 方法 1：使用 normal! 模拟 visual 选择
    normal! 0v4l  # 从行首选择 4 个字符
    # 此时 '[ 在 (1,1), '] 在 (1,5)

    # 方法 2：直接设置字符级 marks（更可靠，推荐）
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])

    text.SurroundSimple('markdownBold')
    assert_equal('**Hell**o world', getline(1))
enddef
```

**注意**：`normal!` 在 headless 模式下可能不稳定，推荐**直接设置 marks**。多字节字符测试必须使用 `setcharpos()` 而非 `setpos()`。

#### 8.2 光标位置设置

```vim
# 正确方式（推荐字符级API）
setcursorcharpos(1, 5) # 字符位置（推荐）
charcol('.')             # 获取字符列号

# 错误方式：使用 col('.') 获取字节位置后直接用于多字节文本
# 错误方式：使用 cursor() 设置字节位置
```

**注意**：多字节字符测试中，**必须**使用 `setcursorcharpos()` 和 `charcol()`，而非 `cursor()` 和 `col('.')`。

#### 8.3 语法高亮依赖

`IsInRange()` 依赖 `synID()` 检测语法高亮：

```vim
def Test_syntax_dependent()
    setline(1, '**bold** text')
    setlocal filetype=markdown
    setlocal syntax=markdown

    # 确保语法文件已加载
    runtime! syntax/markdown.vim

    setcursorcharpos(1, 3)  # 光标在 "bold" 上（字符位置）
    var range = utils.IsInRange()
    assert_true(has_key(range, 'markdownBold'))
enddef
```

### 规则 9: 常见陷阱

#### 9.1 `setline` 会清除 marks

```vim
# 错误：setline 后 '[ 和 '] 失效
setline(1, 'Hello world')
normal! 0v4l          # 设置 marks
setline(1, 'new text') # marks 被清除！
text.SurroundSimple('markdownBold') # 会失败
```

**正确做法**：先设置文本，再设置 marks，最后调用函数：
```vim
setline(1, 'Hello world')
normal! 0v4l
text.SurroundSimple('markdownBold')
```

#### 9.2 `normal!` 在 headless 模式下的限制

- `normal!` 不会触发所有 autocmd
- 某些操作（如 `:normal! gg`）可能需要 `redraw` 才能生效
- 推荐优先使用 API（`setline`, `setcursorcharpos`, `setcharpos`）而非 `normal!`

#### 9.3 缓冲区清理

每个测试函数应该清理自己创建的缓冲区：

```vim
def Test_with_cleanup()
    new  # 创建新缓冲区
    try
        setline(1, 'test')
        # ... 测试逻辑 ...
    finally
        bwipe!  # 清理缓冲区
    endtry
enddef
```

#### 9.4 错误预期测试

使用 `assert_fails()` 测试预期失败：

```vim
def Test_invalid_style()
    assert_fails("text.SurroundSimple('invalid')", 'E117:')
enddef
```

#### 9.5 多字节陷阱

详见 `doc/multibyte-handling-summary.md` §3.5。最常见的三类错误：

1. **字节/字符混用** — 用 `setpos()` 设字节位置，却用 `strcharpart()` 按字符截取
2. **基数转换遗漏** — `getcharpos()` 返回 1-based，`strcharpart()` 需要 0-based，忘记减 1
3. **字符类型覆盖不足** — 仅测 ASCII 或仅测中文，未覆盖混合场景

## 示例：完整的测试文件

`test/test-text/test-surround-simple.vim`:

```vim
vim9script

source ../init.vim
import autoload '../../autoload/mplus/text.vim' as text

setlocal filetype=markdown
setlocal syntax=markdown

# --- Test: Bold surround single line ---
def Test_bold_single_line()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**Hell**o world', getline(1))
enddef

# --- Test: Italic surround single line ---
def Test_italic_single_line()
    setline(1, 'Hello world')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 5, 0])
    text.SurroundSimple('markdownItalic')
    assert_equal('*Hell*o world', getline(1))
enddef

# --- Test: Bold multi-line ---
def Test_bold_multi_line()
    setline(1, ['Hello', 'beautiful', 'world'])
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 2, 9, 0])
    text.SurroundSimple('markdownBold')
    assert_equal('**Hello', getline(1))
    assert_equal('beautiful**', getline(2))
    assert_equal('world', getline(3))
enddef

# --- Test: CJK characters ---
def Test_bold_cjk()
    setline(1, '你好世界')
    setcharpos("'[", [0, 1, 1, 0])
    setcharpos("']", [0, 1, 3, 0])  # 选择 "你好世"（3 个字符）
    text.SurroundSimple('markdownBold')
    assert_equal('**你好世**界', getline(1))
enddef

# --- Test: Emoji mixed ---
def Test_bold_emoji()
    setline(1, 'Hello😀世界')
    setcharpos("'[", [0, 1, 6, 0])
    setcharpos("']", [0, 1, 7, 0])  # 选择 "😀"
    text.SurroundSimple('markdownBold')
    assert_equal('Hello**😀**世界', getline(1))
enddef

# --- Run all tests ---
Test_bold_single_line()
Test_italic_single_line()
Test_bold_multi_line()
Test_bold_cjk()
Test_bold_emoji()

# --- Report ---
if len(v:errors) > 0
    for err in v:errors
        echoerr err
    endfor
    cquit!
else
    echo 'test-surround-simple: All tests passed'
    quitall!
endif
```

## CI 集成

在 GitHub Actions 中跨平台测试：

```yaml
name: Tests
on: [push, pull_request]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
      - name: Run tests (Linux/macOS)
        if: runner.os != 'Windows'
        run: |
          cd test
          make test
      - name: Run tests (Windows)
        if: runner.os == 'Windows'
        run: |
          cd test
          .\run-tests.ps1
```

### 测试覆盖率

Vim 没有原生的代码覆盖率工具，但可以通过以下方式近似评估：

1. **手动追踪**：在测试指南中列出每个函数及其测试状态
2. **CI 日志分析**：检查 `v:errors` 输出，确保所有测试都运行
3. **代码审查**：PR 中新增代码必须附带对应测试

## 快速开始

1. 创建 `test/` 目录和 `test/init.vim`
2. 从 `test/test-text/` 开始，这是最核心、最容易测试的模块
3. 使用 `test-surround-simple.vim` 作为模板
4. 验证运行：
   - **Linux/macOS/Git Bash**: `cd test && make test-text`
   - **Windows PowerShell**: `cd test; .\run-tests.ps1 test-text`
   - **Windows CMD**: `cd test & run-tests.cmd`
5. 逐步扩展到其他测试组

### 给 AI 的提示词模板

当使用 AI 编写测试时，可以直接复制以下提示词：

```
请为 vim-markdown-plus 的 mplus/text.vim 中的 SurroundSimple 函数编写测试。

要求：
1. 使用 vim9script 语法
2. 使用 Vim 内置 assert_* 函数
3. 测试场景：单行选择、多行选择、CJK 字符、Emoji 混合、空选择
4. 使用 setcharpos() 设置 '[ 和 '] marks（字符位置），不使用 setpos()
5. 使用 setcursorcharpos() 设置光标，不使用 cursor()
6. 每个测试函数独立，包含 setup/execute/assert
7. 测试文件末尾调用所有测试函数并检查 v:errors
8. 多字节处理遵循 doc/multibyte-handling-summary.md

参考模板见 TESTING.md 中的"示例：完整的测试文件"部分。
```
