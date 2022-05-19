---
title: vim笔记
hidden: false
katex: true
typora-copy-images-to: ../../img
date: 2022-01-27 15:42:06
updated: 2022-01-27 15:42:06
tags: vim
categories: Default
---



<!-- more -->



## 配置

```bash
set expandtab
set softtabstop=2
set autoindent
set tabstop=2
set shiftwidth=2
set nu
syntax on

noremap H ^
noremap L $
noremap J G
noremap K gg
nnoremap < <<
nnoremap > >>

"自动补全
inoremap ( ()<ESC>i
inoremap [ []<ESC>i
inoremap { {}<ESC>i
inoremap ' ''<ESC>i
inoremap " ""<ESC>i
"inoremap { {<CR>}<ESC>i
```



## 快捷键

| 命令                      | 含义                          |
| ------------------------- | ----------------------------- |
| h/j/k/l                   | 左/下/上/右                   |
| ^/$                       | 行首/行尾                     |
| w/b                       | 上一个单词/下一个单词         |
| f{char}/F{char}           | 上一个字符/下一个字符         |
| i/a                       | 光标前插入                    |
| I/A                       | 行首插入/行尾插入             |
| o/O                       | 行后插入/行前插入             |
| dd                        | 删除一行                      |
| dt{w}                     | 删除当前直到某个字符          |
| diw                       | 删除光标所在单词              |
| v/V/ctrl + v              | 字符单位/行单位/列单位        |
| aw                        | 当前单词及空格                |
| i(                        | 括号内的内容，(、[、{、"      |
| a(                        | 括号和括号内的内容 (、[、{、" |
| :s#/home/user#/home/sanzo | 将/home/user替换为/home/sanzo |
|                           |                               |
|                           |                               |
|                           |                               |
|                           |                               |





文本对象



<!-- Q.E.D. -->
