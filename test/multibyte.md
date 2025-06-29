# vim-markdown-plus 多字节字符支持测试用例

## 测试说明

本文件用于测试 vim-markdown-plus 插件的 SurroundSmart 功能在多字节字符场景下的表现。
测试时请将光标放在目标单词/字符上，使用 `<localleader>biw` 等命令进行包裹操作，
然后通过 `:messages` 观察调试输出。

## 1. 纯英文测试

This is a book about dragon.

测试点：
- 光标在 "book" 上，`<localleader>biw` 应包裹 "book"
- 光标在 "dragon" 上，`<localleader>biw` 应包裹 "dragon"

## 2. 纯中文测试

这是一本关于龙的书。

测试点：
- 光标在 "本" 上，`<localleader>biw` 应包裹 "本"
- 光标在 "龙" 上，`<localleader>biw` 应包裹 "龙"
- 光标在 "关于" 上，`<localleader>biw` 应包裹 "关于"

## 3. 中英文混合测试

This is 这是 a 一本 book 书 about 关于 dragon 龙。

测试点：
- 光标在 "book" 上，`<localleader>biw` 应包裹 "book"
- 光标在 "书" 上，`<localleader>biw` 应包裹 "书"
- 光标在 "关于" 上，`<localleader>biw` 应包裹 "关于"
- 光标在 "dragon" 上，`<localleader>biw` 应包裹 "dragon"
- 光标在 "龙" 上，`<localleader>biw` 应包裹 "龙"

## 4. Emoji 和特殊符号测试

这是一本📚关于🐉的书。

测试点：
- 光标在 "📚" 上，`<localleader>biw` 应包裹 "📚"
- 光标在 "🐉" 上，`<localleader>biw` 应包裹 "🐉"

## 5. 行首/行尾/边界测试

book
这是

测试点：
- 光标在行首 "book" 上，`<localleader>biw` 应包裹 "book"
- 光标在行尾 "这是" 上，`<localleader>biw` 应包裹 "这是"

## 6. 跨多行选区测试

This is a
book about
dragon.

测试点：
- 选中多行文本，`<localleader>biw` 应正确包裹整个选区

## 7. 复杂混合场景测试

Hello 你好 world 世界！This is 这是 a 一本 book 书 about 关于 dragon 龙。📚🐉

测试点：
- 光标在任意英文单词上，应正确包裹
- 光标在任意中文字符上，应正确包裹
- 光标在 emoji 上，应正确包裹

## 8. 极端边界测试

a
b
c

测试点：
- 单字符行的包裹
- 空行附近的包裹

## 9. 数字和符号混合测试

123 数字 456 测试 789

测试点：
- 光标在数字上，应正确包裹
- 光标在中文上，应正确包裹

## 10. 长文本压力测试

这是一个非常长的中文句子，包含了很多中文字符，用来测试在长文本中多字节字符的包裹功能是否正常工作。

测试点：
- 在长文本中任意位置进行包裹操作
- 观察是否出现索引错位或字符丢失

## 测试命令参考

- `<localleader>biw` - 加粗包裹
- `<localleader>iiw` - 斜体包裹
- `<localleader>siw` - 删除线包裹
- `<localleader>ciw` - 行内代码包裹

## 调试输出观察

执行包裹操作后，使用 `:messages` 查看调试输出，重点关注：

- `[SurroundSmart]` - 智能包裹的变量和切片信息
- `[SurroundSimple]` - 简单包裹的变量和切片信息
- `[IsInRange]` - 区间检测的位置信息
- `[ToggleSurround]` - 包裹切换的决策信息

观察输出中的列号、切片内容、最终 setline 内容是否符合预期。
