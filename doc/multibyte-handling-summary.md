# Vimscript 多字节字符处理与实战经验总结

Vimscript 在处理多字节（Multibyte）字符（如中文、日文、Emoji 等）时，常因字节与字符单位混用导致光标定位、文本范围、文本替换等功能失效。本文系统梳理多字节支持的原理、常见陷阱、API 替换、实战案例与最佳实践，供插件开发与维护参考。

## 1. Vimscript 中的字节与字符

Vimscript 涉及两套位置与长度单位：

- **字节 (Byte)**：
  - ASCII字符（英文字母、数字、符号）：1字节
  - 中文字符（UTF-8编码）：3字节
  - Emoji表情符号（UTF-8编码）：4字节
- **字符 (Character)**：每个字符算作 1 单位，符合用户直觉。

**混用两种单位的 API 是多字节 bug 的根源。**

## 2. 多字节环境下的 API 选择

Vimscript 多字节处理的核心是统一使用字符单位而非字节单位。

### 2.1 关键 API 的字节字符对照表

 | 场景            | 旧函数 (字节)        | 新函数 (字符)            | 说明                        |
 | :-------------- | :------------------  | :----------------------  | :-------------------------- |
 | 字符串长度      | `len(string)`        | `strchars(string)`       | 计算字符数而非字节数        |
 | 字符串长度      | `strlen(string)`     | `strchars(string)`       | 计算字符数而非字节数        |
 | 光标列号        | `col('.')`           | `charcol('.')`           | 获取字符列位置              |
 | 字符串截取      | `strpart(str, i, l)` | `strcharpart(str, i, l)` | 按字符位置截取字符串        |
 | 字符串匹配      | `match(str, pat)`    | `matchstr(str, pat)`     | 返回匹配的字符串而非位置    |
 | 位置搜索        | `searchpos(pat)`     | -                        | 返回字节列号，需转换        |
  | 光标位置获取    | `getpos('.')`        | `getcursorcharpos()`     | 获取字符位置而非字节位置    |
  | 选区位置        | `getpos("'[")`       | `getcharpos("'[")`       | 获取字符位置而非字节位置    |
  | 光标位置设置    | `setpos('.', pos)`   | `setcursorcharpos(pos)`  | 设置字符位置而非字节位置    |
  | 光标移动        | `cursor(lnum, col)`  | `setcursorcharpos(lnum, col)` | `cursor()` 接受字节列号 |
 | 标记位置设置    | `setpos("'[", pos)`  | `setcharpos("'[", pos)`  | 设置字符位置而非字节位置    |
 | 字符索引转换    | -                    | `charidx(str, byte_idx)` | 字节索引转字符索引          |
 | 字节索引转换    | -                    | `byteidx(str, char_idx)` | 字符索引转字节索引          |

**经验总结**：
- **列号相关**的API（如 `col('.')`、`getpos()`、`searchpos()` 等）大多返回字节列号。
- **字符串操作**的API中，以"char"为前缀的函数（如 `charcol()`、`strcharpart()`、`strchars()`、`getcharpos()`、`setcharpos()`、`getcursorcharpos()`、`setcursorcharpos()`）以及 `matchstr()` 等是字符安全的。
- 进行任何文本操作前，务必统一所有列号的单位，避免混用。
- **强烈推荐优先使用字符级位置API**，它们直接处理字符位置，避免转换开销和潜在错误。
- 多字节支持的本质是**全链路统一字符单位**（仅 `synID()` 等少数 API 必须传字节列号，需局部 `byteidx()` 转换）。

### 2.2 常见 API 的基数规则

在多字节字符处理中，基数规则（1-based vs 0-based）的重要性被放大：
**字节与字符的转换本身就容易出错，再加上基数不一致，极易导致光标偏移、文本截取错误、选区范围不准确等问题** 。

 | API/函数                 | 行号基数   | 列号基数   | 备注                           |
 | ------------------------ | ---------- | ---------- | ------------------------------ |
 | getline()                | 1-based    | -          | 行号从 1 开始                  |
 | searchpos()              | 1-based    | 1-based    | 返回 [lnum, byte_col]          |
 | col('.')                 | 1-based    | 1-based    | 当前光标字节列号               |
 | charcol('.')             | 1-based    | 1-based    | 当前光标字符列号               |
 | getpos()                 | 1-based    | 1-based    | 返回字节列号                   |
 | getcharpos()             | 1-based    | 1-based    | 返回字符列号                   |
 | setpos()                 | 1-based    | 1-based    | 接受字节列号                   |
 | setcharpos()             | 1-based    | 1-based    | 接受字符列号                   |
 | getcursorcharpos()       | 1-based    | 1-based    | 返回字符位置，用于光标操作     |
 | setcursorcharpos()       | 1-based    | 1-based    | 接受字符位置，用于光标操作     |
 | strcharpart()            | -          | 0-based    | 起始字符索引 0-based           |
 | charidx()                | -          | 0-based    | 输入/输出均为 0-based          |
 | byteidx()                | -          | 0-based    | 输入/输出均为 0-based          |
 | match()                  | -          | 0-based    | 返回匹配起始字节索引           |
 | matchstr()               | -          | 0-based    | 返回匹配的字符串               |
 | synID()                  | 1-based    | 1-based    | 只接受字节列号                 |

### 2.3 字符/字节互转方法

在多字节文本处理中，字符索引与字节索引的互转极为常见，以下是核心的互转方法与注意事项：

#### 2.3.1 字节索引转字符索引

- **charidx({text}, {byte_idx})**
  - 作用：将某行的字节索引（0-based）转换为字符索引（0-based）。
  - 用法：
    ```vim
    let byte_col = 10     " 1-based 字节列号（如 col('.') 或 searchpos() 返回）
    let char_col = charidx(line, byte_col - 1) + 1  " 0-based 字节索引转 1-based 字符列号
    ```
  - 典型场景：searchpos()、getpos()、match()等API返回的列号都是字节列号，需先转换。

#### 2.3.2 字符索引转字节索引

- **byteidx({text}, {char_idx})**
  - 作用：将某行的字符索引（0-based）转换为字节索引（0-based）。
  - 用法：
    ```vim
    let char_col = 5
    let byte_col = byteidx(line, char_col - 1) + 1  " 得到1-based字节列号
    ```
  - 典型场景：需要与只接受字节列号的API（如synID、setpos等）交互时。

## 3. 最佳实践指南

### 3.1 新插件的设计建议
对于新开发的插件，建议从设计阶段就考虑多字节支持：

#### 3.1.1 统一使用字符级API
- 进入复杂逻辑前，**所有位置变量全部转换为字符单位**
- 只用 `strchars`、`charcol`、`charidx`、`strcharpart`、`getcharpos`、`setcharpos`、`getcursorcharpos`、`setcursorcharpos` 等字符级 API；遇到 `synID()`、`searchpos()` 等必须传字节列号的 API 时，用 `byteidx()` 做局部转换

```vim
" 从一开始就使用字符级API，避免后续改造
let char_count = strchars(text)
let char_part = strcharpart(text, start, len)
let char_pos = charcol('.')
let cursor_pos = getcursorcharpos()  " 直接获取字符位置
let start_pos = getcharpos("'[")     " 直接获取字符位置
```

**实际项目中的推荐做法：**
```vim
" 推荐：直接使用字符级API，避免转换
let lA = line("'[")
let cA = charcol("'[")  " 直接获取字符列号
let lB = line("']")
let cB = charcol("']")  " 直接获取字符列号

" 使用字符列号进行文本操作
let toA = strcharpart(getline(lA), 0, cA - 1) . open_delim
let fromB = close_delim . strcharpart(getline(lB), cB)
```

#### 3.1.2 封装位置处理函数
```vim
" 创建统一的位置处理接口
function! s:GetCharPosition(line, byte_col)
    return charidx(a:line, a:byte_col - 1) + 1
endfunction

function! s:GetBytePosition(line, char_col)
    return byteidx(a:line, a:char_col - 1) + 1
endfunction

" 推荐：直接使用字符位置API，避免转换
function! s:GetCursorCharPos()
    return getcursorcharpos()
endfunction

function! s:SetCursorCharPos(line, col)
    setcursorcharpos([a:line, a:col])
endfunction

function! s:GetSelectionCharPos()
    return [getcharpos("'["), getcharpos("']")]
endfunction
```

#### 3.1.3 设计时考虑多字节字符边界
多字节字符边界是多字节处理中的核心概念，指在多字节文本中，字符与字节之间的不对应关系。

**什么是多字节字符边界？**

在多字节文本中，一个字符可能占用多个字节，其可能造成如下边界问题：

1. **字节索引截断字符**
   ```vim
   " ❌ 错误：字节索引可能截断多字节字符
   let text = "Hello世界"
   let part = strpart(text, 0, 5)  " 截取前5个字节
   " 结果：part = "Hello" ✓ 正确

   let part2 = strpart(text, 0, 6)  " 截取前6个字节
   " 结果：part2 = "Hello" ✗ 截断了"世"字（3字节）
   ```

2. **循环遍历时的边界错误**
   ```vim
   " ❌ 错误：用字节索引遍历字符
   let text = "Hello世界"
   let i = 0
   while i < strlen(text)  " 使用字节长度
       let char = strpart(text, i, 1)  " 每次取1字节
       echo char
       let i += 1
   endwhile
   " 结果：会输出不完整的字符片段

   " ✅ 正确：用字符索引遍历
   let i = 0
   while i < strchars(text)  " 使用字符长度
       let char = strcharpart(text, i, 1)  " 每次取1字符
       echo char
       let i += 1
   endwhile
   " 结果：正确输出每个字符
   ```

**设计时的边界考虑：**

1. **避免假设字符长度**
   ```vim
   " ❌ 错误：假设每个字符占用固定字节数
   let char_width = 3  " 假设每个字符3字节
   let char_count = strlen(text) / char_width  " 在多字节文本中错误

   " ✅ 正确：使用字符级API
   let char_count = strchars(text)  " 直接获取字符数
   ```

2. **边界检查的重要性**
   ```vim
   " ✅ 正确：进行边界检查
   let text = "Hello世界"
   let line_len = strchars(text)
   let safe_start = min([start_pos, line_len])
   let safe_len = min([length, line_len - safe_start])
   let result = strcharpart(text, safe_start, safe_len)
   ```

3. **测试用例设计**
   ```vim
   " 测试用例应包含各种字符类型
   let test_cases = [
       \ "Hello",           "纯ASCII"
       \ "Hello世界",       "ASCII+中文"
       \ "世界Hello",       "中文+ASCII"
       \ "Hello😀世界",     "ASCII+Emoji+中文"
       \ "😀世界Hello",     "Emoji+中文+ASCII"
       \ ]
   ```

#### 3.1.4 使用Vim内置的文本对象
```vim
" 优先使用Vim的文本对象，减少手动位置计算
normal! ciw  " 而不是手动计算单词边界
normal! di"  " 而不是手动查找引号位置
```

### 3.2 现有插件的改造经验
许多Vim插件最初只支持ASCII，后来才支持多字节。改造过程中主要涉及以下方面：

#### 3.2.1 位置计算相关
- 原问题：使用 `len()`、`strpart()` 等字节级函数计算位置
- 改造方案：替换为 `strchars()`、`strcharpart()` 等字符级函数
- 典型场景：文本截取、光标定位、选区范围计算

#### 3.2.2 正则表达式匹配
- 原问题：使用 `match()` 返回字节位置进行后续处理
- 改造方案：使用 `matchstr()` 直接获取匹配内容，或对 `match()` 结果进行字符位置转换
- 典型场景：语法高亮、文本搜索替换

#### 3.2.3 选区操作
- 原问题：直接使用 `getpos()` 返回的字节列号进行文本操作
- 改造方案：通过 `charidx()` 转换为字符列号后再操作
- 典型场景：surround插件、文本对象操作

#### 3.2.4 循环和边界条件
- 原问题：循环中使用字节索引，在多字节文本下提前终止或越界
- 改造方案：统一使用字符索引，重新设计循环逻辑
- 典型场景：文本解析、逐字符处理

### 3.3 易混淆API的最佳实践
在实际开发中，某些API特别容易在多字节环境下出错，需要特别注意其正确用法：

#### 3.3.1 searchpos() 搜索位置
- **返回值格式**：`[line, byte_col]`，其中 `byte_col` 是字节列号（1-based）
- **常见用法**：搜索模式并返回匹配位置
- **问题**：返回的列号是字节列号，在多字节文本中不能直接用于字符级操作

**典型错误示例：**
```vim
" ❌ 错误：直接用字节列号进行字符级操作
let pos = searchpos('word', 'W')
let line = getline(pos[0])
let matched_text = strcharpart(line, pos[1] - 1, 4)  " 假设单词长度为4
" 在多字节文本中，matched_text 可能为空或错误
```

**正确处理方法：**
```vim
" ✅ 正确：先转换为字符列号
let pos = searchpos('word', 'W')
let line = getline(pos[0])

" 转换为字符列号
let char_col = charidx(line, pos[1] - 1) + 1

" 使用字符列号进行文本操作
let matched_text = strcharpart(line, char_col - 1, 4)
```

**封装为通用函数：**
```vim
function! s:SearchPattern(pattern, flags)
    let pos = searchpos(a:pattern, a:flags)
    if pos[0] == 0
        return {}  " 未找到匹配
    endif

    let line = getline(pos[0])
    let char_col = charidx(line, pos[1] - 1) + 1

    return {
        \ 'line': pos[0],
        \ 'byte_col': pos[1],
        \ 'char_col': char_col,
        \ 'line_text': line
        \ }
endfunction

" 使用示例
let result = s:SearchPattern('word', 'W')
if !empty(result)
    echo "找到匹配，字符列号：" . result.char_col
endif
```

**常见flags说明：**
- `'W'`：向前搜索，不换行
- `'b'`：向后搜索
- `'n'`：不移动光标
- `'c'`：不区分大小写

#### 3.3.2 getpos() 选区标记
- **返回值格式**：`[bufnum, lnum, col, off]`，其中 `col` 是字节列号（1-based）
- **常见用法**：`getpos("'[")` 获取选区起始位置，`getpos("']")` 获取选区结束位置
- **问题**：返回的列号是字节列号，在多字节文本中不能直接用于字符级操作

**典型错误示例：**
```vim
" ❌ 错误：直接用字节列号进行字符级操作
let start_pos = getpos("'[")
let end_pos = getpos("']")
let line = getline(start_pos[1])
let selected_text = strcharpart(line, start_pos[2] - 1, end_pos[2] - start_pos[2])
" 在多字节文本中，selected_text 可能为空或错误
```

**正确处理方法：**
```vim
" ✅ 正确：先转换为字符列号
let start_pos = getpos("'[")
let end_pos = getpos("']")
let line = getline(start_pos[1])

" 转换为字符列号
let start_char_col = charidx(line, start_pos[2] - 1) + 1
let end_char_col = charidx(line, end_pos[2] - 1) + 1

" 使用字符列号进行文本操作
let selected_text = strcharpart(line, start_char_col - 1, end_char_col - start_char_col)
```

#### 3.3.3 字符级位置API的推荐用法
- **getcharpos()/setcharpos()**：直接处理标记位置，无需转换
- **getcursorcharpos()/setcursorcharpos()**：直接处理光标位置，无需转换
- **优势**：避免字节/字符转换，减少错误，提高性能
- **注意**：即使光标已通过 `setcursorcharpos()` 正确定位，`synID()` 仍只接受字节列号——需用 `byteidx()` 转换（详见 3.5.9）

**详细API说明：**

**getcursorcharpos()**
- 作用：获取当前光标位置，返回字符列号（1-based）
- 用法：
  ```vim
  let char_pos = getcursorcharpos()  " 返回 [bufnum, lnum, char_col, off]
  ```
- 典型场景：需要保存和恢复光标字符位置时使用

**setcursorcharpos({list})**
- 作用：设置光标位置，接受字符列号（1-based）
- 用法：
  ```vim
  setcursorcharpos([line, char_col])  " 设置光标到指定字符位置
  ```
- 典型场景：需要移动光标到指定字符位置时使用

**getcharpos({expr})**
- 作用：获取标记位置，返回字符列号（1-based）
- 用法：
  ```vim
  let start_pos = getcharpos("'[")  " 获取选区起始字符位置
  let end_pos = getcharpos("']")    " 获取选区结束字符位置
  ```
- 典型场景：需要获取选区或标记的字符位置时使用

**setcharpos({expr}, {list})**
- 作用：设置标记位置，接受字符列号（1-based）
- 用法：
  ```vim
  setcharpos("'[", [bufnum, line, char_col, off])  " 设置标记位置
  ```
- 典型场景：需要保存和恢复标记位置时使用

**典型用法示例：**
```vim
" ✅ 推荐：直接使用字符位置API
let cursor_pos = getcursorcharpos()
let start_pos = getcharpos("'[")
let end_pos = getcharpos("']")

" 直接使用字符列号，无需转换
let line = getline(cursor_pos[1])
let selected_text = strcharpart(line, start_pos[2] - 1, end_pos[2] - start_pos[2])
```

**实际项目中的推荐做法：**
```vim
" 推荐：使用getcursorcharpos/setcursorcharpos
let saved_curpos = getcursorcharpos()  " 保存字符位置
setcursorcharpos(new_line, new_char_col)  " 设置字符位置
```

**与字节级API的对比：**
```vim
" ❌ 需要转换：getpos()返回字节列号
let byte_pos = getpos('.')
let char_col = charidx(getline(byte_pos[1]), byte_pos[2] - 1) + 1

" ✅ 直接使用：getcharpos()返回字符列号
let char_pos = getcharpos('.')
let char_col = char_pos[2]  " 直接使用，无需转换
```

### 3.4 不同场景的解决方案

#### 3.4.1 简单文本操作场景
对于简单的文本插入、删除操作，可以使用Vim的内置命令：
```vim
" 使用Vim的文本对象，避免手动计算位置
normal! ciw  " 删除当前单词并进入插入模式
normal! diw  " 删除当前单词
normal! yiw  " 复制当前单词
```

#### 3.4.2 复杂文本处理场景
对于需要精确控制的复杂操作，使用字符级API：

**场景1：单行选区文本替换**
```vim
" 获取选区位置（字符列号，无需转换）
let start_pos = getcharpos("'[")
let end_pos = getcharpos("']")
let line = getline(start_pos[1])

" 构建新内容
let before = strcharpart(line, 0, start_pos[2] - 1)
let after = strcharpart(line, end_pos[2])
let new_content = "![book]()"  " 要插入的新内容

" 一步替换
setline(start_pos[1], before . new_content . after)
```

**适用场景**：单行文本的简单替换操作，如将选中文本替换为固定内容。

**场景2：光标位置插入文本**
```vim
" 在光标位置插入文本
let line = getline('.')
let char_pos = charcol('.')
let before = strcharpart(line, 0, char_pos - 1)
let after = strcharpart(line, char_pos)
setline('.', before . new_text . after)
```

#### 3.4.3 正则表达式场景
正则表达式在多字节环境下的处理：
```vim
" 使用 \zs 和 \ze 避免位置计算
let pattern = 'word\zs'
let replacement = 'new_word'
execute 's/' . pattern . '/' . replacement . '/g'
```

#### 3.4.4 性能考虑
- **字符级API开销**：`strchars()`、`charidx()` 等函数比字节级API慢
- **缓存策略**：对于频繁访问的文本，考虑缓存字符位置
- **批量操作**：尽量批量处理，减少API调用次数

### 3.5 多字节陷阱与反例

#### 3.5.1 字符串长度陷阱
**陷阱：混用字节长度和字符长度**
```vim
" ❌ 错误：用字节长度判断字符数
let text = "Hello世界"
let char_count = len(text)  " 返回字节数：11，而非字符数：7
if char_count > 10
    echo "文本太长"  " 在多字节文本中判断错误
endif
```
**问题**：`len()` 返回字节数，在多字节文本中不等于字符数。

**正确做法：**
```vim
" ✅ 正确：使用字符长度
let text = "Hello世界"
let char_count = strchars(text)  " 返回字符数：7
if char_count > 10
    echo "文本太长"
endif
```

#### 3.5.2 字符串截取陷阱
**陷阱：用字节索引截取字符串**
```vim
" ❌ 错误：用字节索引截取
let text = "Hello世界"
let part = strpart(text, 0, 5)  " 可能截取到不完整的字符
```
**问题**：`strpart()` 使用字节索引，可能截断多字节字符。在多字节文本中，字节索引和字符索引不对应，导致截取到不完整的字符。

**边界问题详解：**
```vim
" 示例：字节索引截断字符
let text = "Hello世界"
" 字节布局：H(1) + e(1) + l(1) + l(1) + o(1) + 世(3) + 界(3)
" 字符布局：H(1) + e(1) + l(1) + l(1) + o(1) + 世(1) + 界(1)

let part1 = strpart(text, 0, 5)   " 截取前5字节：Hello ✓
let part2 = strpart(text, 0, 6)   " 截取前6字节：Hello ✗ 截断"世"字
let part3 = strpart(text, 0, 8)   " 截取前8字节：Hello ✗ 截断"世"字
let part4 = strpart(text, 0, 9)   " 截取前9字节：Hello世 ✓
```

**正确做法：**
```vim
" ✅ 正确：用字符索引截取
let text = "Hello世界"
let part = strcharpart(text, 0, 5)  " 按字符截取：Hello ✓
let part2 = strcharpart(text, 0, 6) " 按字符截取：Hello世 ✓
```

#### 3.5.3 光标定位陷阱
**陷阱：使用字节列号定位光标**
```vim
" ❌ 错误：用字节列号设置光标
let pos = getpos('.')
setpos('.', [bufnum, line, pos[2] + 1, 0])  " 在多字节文本中偏移错误
```
**问题**：字节列号的增量不等于字符位置的增量。

**正确做法：**
```vim
" ✅ 正确：用字符列号定位
let char_pos = getcursorcharpos()
setcursorcharpos(char_pos[1], char_pos[2] + 1)  " 字符位置增量
```

#### 3.5.4 正则表达式陷阱
**陷阱：使用match()返回的字节位置**
```vim
" ❌ 错误：用字节位置进行后续处理
let pos = match(line, 'word')
let after_match = strcharpart(line, pos, 10)  " pos是字节索引
```
**问题**：`match()` 返回字节索引，直接用于字符级操作会出错。

**正确做法：**
```vim
" ✅ 正确：转换为字符位置或使用matchstr()
let matched = matchstr(line, 'word')  " 直接获取匹配内容
" 或者
let pos = match(line, 'word')
let char_pos = charidx(line, pos)  " 转换为字符索引
let after_match = strcharpart(line, char_pos, 10)
```

#### 3.5.5 选区操作陷阱
**陷阱：直接使用normal命令操作选区**
```vim
" ❌ 错误：在多字节文本中可能失效
normal! gv"_c
normal! `[v`]c
```
**问题**：`gv` 选区和 `[`, `]` 标记在多字节文本下可能指向错误的字节位置。

**正确做法：**
```vim
" ✅ 正确：使用字符级API操作
let start_pos = getcharpos("'[")
let end_pos = getcharpos("']")
let selected = strcharpart(getline(start_pos[1]), start_pos[2] - 1, end_pos[2] - start_pos[2])
```

#### 3.5.6 边界检查陷阱
**陷阱：忽略边界检查**
```vim
" ❌ 错误：可能越界访问
let pos = getpos("'[")
let selected = strcharpart(line, pos[2] - 1, 100)  " 可能超出行长度
```
**问题**：在多字节文本中，字节位置和字符位置的关系复杂，容易越界。字节索引和字符索引的不对应关系，使得边界计算变得困难。

**正确做法：**
```vim
" ✅ 正确：进行边界检查
let pos = getpos("'[")
let line = getline(pos[1])
let line_len = strchars(line)
let char_col = charidx(line, pos[2] - 1) + 1
let safe_len = min([desired_length, line_len - char_col + 1])
let selected = strcharpart(line, char_col - 1, safe_len)
```

**边界检查要点：**

边界检查的核心是确保索引在有效范围内，避免越界访问：

1. **使用字符级长度**：`strchars(line)` 获取字符数而非字节数
2. **检查起始位置**：`min([char_col - 1, line_len])` 确保不超出行长度
3. **检查截取长度**：`min([desired_length, line_len - char_col + 1])` 确保不超过可用字符数

**关键原则：**
- 始终使用字符级API进行长度计算
- 使用 `min()`、`max()` 限制范围
- 考虑空字符串、超长文本等边界情况

#### 3.5.7 基数转换陷阱

基数转换是多字节处理中最常见的错误来源。1-based 和 0-based 的混用，加上字节/字符单位的转换，极易导致 off-by-one 错误。

**基数转换秘籍：**

- `getpos()`/`searchpos()` 得到的列号用于 `strcharpart`/`charidx` 时，需减 1（1-based → 0-based）
- `charidx`/`byteidx` 得到的索引若要用于 `setpos`/`synID`，需加 1（0-based → 1-based）

**常见错误模式：**

1. **直接使用 1-based 列号作为 0-based 索引**
   ```vim
   " ❌ 错误：忘记基数转换
   let pos = getpos("'[")
   let selected = strcharpart(line, pos[2], 10)  " pos[2]是1-based，strcharpart需要0-based
   ```
   **问题**：跳过第一个字符，选区范围错误。

2. **忘记 0-based 到 1-based 的转换**
   ```vim
   " ❌ 错误：忘记基数转换
   let char_idx = charidx(line, byte_col)
   setpos("'[", [bufnum, line, char_idx, 0])  " charidx返回0-based，setpos需要1-based
   ```
   **问题**：光标位置偏移一个字符。

**正确的转换模式：**

1. **1-based 列号转 0-based 索引**
   ```vim
   " ✅ 正确：1-based → 0-based
   let pos = getpos("'[")
   let char_col = charidx(line, pos[2] - 1) + 1  " 先转字符列号
   let selected = strcharpart(line, char_col - 1, length)  " 再转0-based索引
   ```

2. **0-based 索引转 1-based 列号**
   ```vim
   " ✅ 正确：0-based → 1-based
   let char_idx = charidx(line, byte_col - 1)
   setpos("'[", [bufnum, line, char_idx + 1, 0])  " 加1转为1-based
   ```

**最佳实践：**

- **统一转换逻辑**：在函数开始就明确标注所有变量的基数
- **封装转换函数**：创建专门的转换函数，避免重复转换逻辑
- **写注释标明基数**：每个涉及位置计算的代码都要标明基数
- **优先使用字符级API**：`getcharpos()`、`setcharpos()` 等直接处理字符位置，减少转换需求

#### 3.5.8 `cursor()` 陷阱：最容易忽略的字节/字符 API

`cursor({lnum}, {col})` 函数接受**字节列号**。当传入字符列号（如 `charcol("'[")` 或 `strchars(line)` 的结果）时，在 CJK 文本中光标会定位到完全错误的位置，导致后续 `IsInRange()` 等基于光标的逻辑产生错误结果。

**典型错误场景：**
```vim
" ❌ 错误：传入字符列号给 cursor()
var lA = line("'[")
var cA = charcol("'[")     " 字符列号，例如 CJK 文本中 cA = 5
cursor(lA, cA)              " cursor() 接受字节列号！CJK 文本中字节≠字符
var range_info = utils.IsInRange()  " 基于错误的光标位置，返回错误结果
```

在 CJK 文本中，字符列号 5 对应的字节列号可能是 11（每个 CJK 字符 3 字节）。`cursor(1, 5)` 将光标定到字节列 5，这可能是某个 CJK 字符的中间位置，语法高亮（`synID`）在此处可能返回空字符串或错误的语法组名。

**问题表现：**
- `IsInRange()` 在光标位置检测不到语法高亮，返回空 `{}`
- 光标在 CJK 字符中间，`synIDattr()` 返回空或错误
- 基于光标位置的字符串截取（`strcharpart`）范围计算错误
- 最终结果缺少分隔符、多余分隔符、或分隔符位置错位

**正确做法：**
```vim
" ✅ 正确：使用 setcursorcharpos() 接受字符列号
var lA = line("'[")
var cA = charcol("'[")        " 字符列号
setcursorcharpos(lA, cA)      " setcursorcharpos() 接受字符列号！
var range_info = utils.IsInRange()  " 基于正确位置，返回正确结果
```

**排查技巧：** 在 `cursor()` 调用前后打印 `charcol('.')` 和 `col('.')` 对比，如果两者不相等且相差很大（CJK 区域），说明传入了字符列号给字节列号函数。

#### 3.5.9 `synID()` 陷阱：必须传入字节列号

`synID({lnum}, {col}, {end})` 只接受**字节列号**。即使光标已通过 `setcursorcharpos()` 正确定位到字符位置，`synID(line, charcol('.'), 1)` 仍会传错列号——`charcol('.')` 返回的是字符列号。

**典型错误：**
```vim
" ❌ 错误：charcol('.') 返回字符列号，synID 需要字节列号
setcursorcharpos(1, 5)                           " 光标在正确字符位置
var style = synIDattr(synID(line('.'), charcol('.'), 1), 'name')
" 在 CJK 文本中，charcol('.')=5 但对应字节列可能是 11
" synID(1, 5) 查看字节列 5，可能是错误位置
```

**正确做法——标准转换模式：**
```vim
" ✅ 正确：byteidx(getline('.'), charcol('.') - 1) + 1 得到字节列号
var bytecol = byteidx(getline('.'), charcol('.') - 1) + 1
var style = synIDattr(synID(line('.'), bytecol, 1), 'name')

" 或在一行中完成：
var style = synIDattr(synID(line("."),
    \ byteidx(getline('.'), charcol(".") - 1) + 1, 1), "name")
```

**注意事项：**
- 此陷阱在纯 ASCII 文本中不表现（字节=字符），但在 CJK/Emoji 区域会导致语法检测完全失效
- `IsInRange()` 等依赖 `synID` 的函数，必须确保传入字节列号
- 这是 **单行最关键的转换**：`byteidx(getline('.'), charcol('.') - 1) + 1`

### 3.6 案例与示例

#### 3.6.1 案例1：综合文本处理示例
展示一个完整的文本处理场景：在多字节文本中查找、替换和格式化文本。

**场景描述：**
在包含中文和英文的Markdown文档中，将选中的文本转换为图片链接格式 `![alt](url)`，同时处理多行文本和特殊字符。

```vim
function! s:ConvertToImageLink()
    " 获取选区范围（直接使用字符级 API，无需转换）
    let start_pos = getcharpos("'[")
    let end_pos = getcharpos("']")

    " 处理单行和多行情况
    if start_pos[1] == end_pos[1]
        " 单行处理
        let line = getline(start_pos[1])

        " 构建新内容（start_pos[2]、end_pos[2] 已是字符列号）
        let before = strcharpart(line, 0, start_pos[2] - 1)
        let selected = strcharpart(line, start_pos[2] - 1, end_pos[2] - start_pos[2])
        let after = strcharpart(line, end_pos[2])

        " 生成图片链接
        let new_content = "![" . selected . "](image.png)"
        setline(start_pos[1], before . new_content . after)
    else
        " 多行处理
        let lines = getline(start_pos[1], end_pos[1])
        let first_line = lines[0]
        let last_line = lines[-1]

        " 处理第一行（start_pos[2] 已是字符列号）
        let first_content = strcharpart(first_line, start_pos[2] - 1)

        " 处理最后一行（end_pos[2] 已是字符列号）
        let last_content = strcharpart(last_line, 0, end_pos[2])

        " 合并所有内容
        let all_content = first_content
        if len(lines) > 2
            let all_content .= "\n" . join(lines[1:-2], "\n")
        endif
        if len(lines) > 1
            let all_content .= "\n" . last_content
        endif

        " 生成图片链接
        let new_content = "![" . all_content . "](image.png)"

        " 替换多行
        call setline(start_pos[1], strcharpart(first_line, 0, start_pos[2] - 1) . new_content)
        if len(lines) > 1
            call deletebufline('%', start_pos[1] + 1, end_pos[1])
        endif
    endif
endfunction

" 使用示例
" 1. 选中单行文本 "Hello世界"，调用函数后变为 "![Hello世界](image.png)"
" 2. 选中多行文本，调用函数后会将所有内容合并为一个图片链接
" 3. 支持包含中文、日文、Emoji等多字节字符的文本
```

**关键点说明：**
- 区分单行和多行处理逻辑
- 使用字符级API确保多字节字符正确处理
- 处理边界情况和特殊字符
- 提供完整的错误处理和边界检查

#### 3.6.2 案例2：字符/字节转换与基数处理
展示完整的字符/字节转换流程和基数处理，包含实际应用场景。

**场景描述：**
在文本编辑器中实现智能搜索和替换功能，需要处理搜索结果的定位、文本提取和位置转换。

```vim
function! s:SmartSearchAndReplace(pattern, replacement)
    " 搜索模式并获取位置
    let pos = searchpos(a:pattern, 'W')
    if pos[0] == 0
        echo "未找到匹配"
        return
    endif

    let line_num = pos[0]           " 1-based 行号
    let byte_col = pos[1]           " 1-based 字节列号
    let line = getline(line_num)

    " 转换为字符列号
    let char_col = charidx(line, byte_col - 1) + 1  " 转为 1-based 字符列号

    " 获取匹配文本的长度（字符数）
    let matched_text = matchstr(line, a:pattern)
    let match_length = strchars(matched_text)

    " 计算替换后的位置
    let before = strcharpart(line, 0, char_col - 1)
    let after = strcharpart(line, char_col - 1 + match_length)
    let new_line = before . a:replacement . after

    " 执行替换
    setline(line_num, new_line)

    " 计算新光标位置
    let new_char_col = char_col + strchars(a:replacement)
    setcursorcharpos(line_num, new_char_col)

    echo "替换完成，新光标位置：" . new_char_col
endfunction

" 使用示例
" call s:SmartSearchAndReplace('world', '世界')  " 将 "world" 替换为 "世界"
```

**关键转换点说明：**
1. **基数转换**：`searchpos()` 返回 1-based 字节列号，用于 `charidx()` 时需要减 1
2. **字符长度计算**：使用 `strchars()` 计算匹配文本的字符数，而非字节数
3. **位置计算**：使用字符列号进行文本截取和拼接
4. **光标定位**：使用 `setcursorcharpos()` 设置字符位置

#### 3.6.3 案例3：CJK 文本中 `cursor()` 误用的实战排查

**背景：** vim-markdown-plus 插件的 Bold/Italic 等样式切换功能（`ToggleSurround`）在 CJK 文本中产生错误结果。用户选中包含已有 `**bold**` 格式的 CJK 文本行，实施 `<localleader>b` 期望整行加粗，但实际结果缺少尾部 `**` 或在错误位置出现多余 `**`。

**问题文本：**
```
在已**有 Windows Terminal 窗口**的新 tab 中打开
```

**现象：** 选中整行（linewise visual），实施 Bold Toggle 后：
- 期望：`**在已有 Windows Terminal 窗口的新 tab 中打开**`
- 实际：`**在已有 Windows Terminal 窗口的新 tab 中打开`（缺少尾部 `**`）

**排查过程：**

1. 添加调试输出，追踪 `SurroundSmart()` 中 `IsInRange()` 的调用位置：
   ```
   [SS] pointB found_interval={'markdownBold': ...} old_left_delimiter=** fromB=[]
   ```
   `fromB=[]`（空字符串）导致尾部 `**` 丢失。

2. 追踪 `IsInRange()` 的光标位置：
   ```
   [IIR] cursor=(1,27) text_style=markdownBoldDelimiter
   ```
   光标应在 (1,37)（行尾），实际却在 (1,27)（`**` 闭合分隔符处）。

3. **根因定位**：`SurroundSmart()` 第 165 行调用 `cursor(lB, cB)`，其中 `cB = strchars(getline(lB))` 返回的是**字符列号**（37），但 `cursor()` 函数接受**字节列号**。该行包含 7 个 CJK 字符（各 3 字节）+ 30 个 ASCII 字符 = 51 字节。`cursor(1, 37)` 将光标定位到字节列 37，在 CJK/ASCII 混合文本中，这刚好是闭合 `**` 的第二个 `*` 字符位置。

4. 光标落在 `*`（闭合分隔符）上，`IsInRange()` 的 delimiter 智能检测将其识别为 `markdownBoldDelimiter`，进而找到粗体范围，触发 `old_left_delimiter == close_delim` 的逻辑，将我们的新 `**` 分隔符删除。同时 `strcharpart(line, 37)` 截取行尾返回空字符串。

**涉及的三种错误模式：**

| 位置 | 错误代码 | 正确代码 | 影响 |
|------|----------|----------|------|
| `text.vim:125` | `cursor(lA, cA)` | `setcursorcharpos(lA, cA)` | 点 A 光标错位，`IsInRange` 结果错误 |
| `text.vim:165` | `cursor(lB, cB)` | `setcursorcharpos(lB, cB)` | 点 B 光标错位，`fromB` 计算错误 |
| `utils.vim:63` | `synID(line, charcol('.'), 1)` | `synID(line, byteidx(...)+1, 1)` | delimiter 检测时语法组查询传错列 |

**修复总结：**
- 3 处 `cursor()` → `setcursorcharpos()`（text.vim 2 处, utils.vim 3 处）
- 3 处 `synID(line, charcol('.'), 1)` → `synID(line, byteidx(getline('.'), charcol('.') - 1) + 1, 1)`（utils.vim）
- 新增 `SelectionExtendsBeyond()` 检查：选区超出已有格式范围时用 `SurroundSmart` 扩展而非 `RemoveSurrounding` 移除
- 新增 `SurroundSmart` 点 A/点 B 的边界位置检查：仅当已有分隔符在 A-B 范围**外**时才剥离，范围内由 `RemoveDelimiters` 统一处理

**教训：**
1. `cursor()` 和 `setcursorcharpos()` 的差异在纯 ASCII 文本中不可见，仅在 CJK/Emoji 区域才暴露——必须用包含多字节字符的测试用例覆盖
2. `synID()` 即使光标已通过 `setcursorcharpos()` 正确定位，仍需用 `byteidx()` 转换列号——这是一个**双重陷阱**
3. 调试此类问题时，打印 `charcol('.')` vs `col('.')` 对比可以快速定位 `cursor()` 误用

## 4. 总结

Vimscript 多字节字符处理的核心在于**统一使用字符单位**，避免字节与字符单位的混用。本文档通过系统性的梳理，为插件开发者提供了完整的解决方案：

- **新插件**：从设计阶段就考虑多字节支持，统一使用字符级API
- **现有插件**：逐步替换字节级API，重点关注位置计算和文本操作部分
- **测试验证**：使用包含中文、日文、Emoji 等多字节字符的测试用例

### 4.1 核心原则
- **统一单位**：绝大多数文本操作都使用字符单位；仅在 `synID()`、`searchpos()` 等必须传字节列号的 API 处做局部 `byteidx()`/`charidx()` 转换
- **优先字符级API**：使用 `getcharpos()`、`setcharpos()`、`getcursorcharpos()`、`setcursorcharpos()` 等字符级位置API
- **边界安全**：始终进行边界检查，避免越界访问
- **基数一致**：明确区分 1-based 和 0-based，避免 off-by-one 错误

### 4.2 关键API替换
- `len()` → `strchars()`：字符长度计算
- `strpart()` → `strcharpart()`：字符级字符串截取
- `col()` → `charcol()`：字符列号获取
- `getpos()` → `getcharpos()`：字符位置获取
- `setpos()` → `setcharpos()`：字符位置设置
- `cursor()` → `setcursorcharpos()`：光标位置设置（`cursor` 接受字节列号）
- `synID(line, charcol('.'), 1)` → `synID(line, byteidx(getline('.'), charcol('.') - 1) + 1, 1)`：`synID` 只接受字节列号

### 4.3 常见问题快速排查
- **光标定位错误**：检查是否使用了 `col('.')` 而非 `charcol('.')`
- **`cursor()` 错位**：检查是否将字符列号传给了 `cursor()`（应改用 `setcursorcharpos()`）
- **`synID` 返回空**：检查是否将 `charcol('.')` 直接传给 `synID()`（需先用 `byteidx()` 转换）
- **文本截取为空**：检查是否使用了 `strpart()` 而非 `strcharpart()`
- **选区操作失效**：检查是否使用了 `getpos()` 而非 `getcharpos()`
- **循环提前终止**：检查循环条件是否混用了字节和字符单位
- **off-by-one错误**：检查基数转换是否正确（1-based ↔ 0-based）
- **调试技巧**：在可疑位置打印 `charcol('.')` vs `col('.')`，不相等说明多字节文本中字节/字符混用

通过遵循这些原则和实践，可以有效避免多字节环境下的常见问题，开发出健壮的 Vimscript 插件。
