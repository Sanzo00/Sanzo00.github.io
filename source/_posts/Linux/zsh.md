---
title: zsh安装与配置
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-10-01 23:11:13
updated: 2021-10-01 23:11:13
tags:
	zsh
categories: Linux
---



<!-- more -->

---

## 下载安装

[ohmyzsh](https://github.com/ohmyzsh/ohmyzsh)

```shell
# 安装zsh
sudo apt install zsh

# 安装ohmyzsh
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 切换shell为zsh
chsh -s /bin/zsh
```



离线安装：

https://www.jianshu.com/p/c65f145772c2

https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH

```bash
# install zsh
https://sourceforge.net/projects/zsh/files/latest/download

xz -d zsh.tar.xz
tar -xf zsh.tar 
```



## 按键映射

```shell
# 编辑.zshrc文件，添加如下配置
vim .zshrc

#Rebind HOME and END to do the decent thing:
bindkey '\e[1~' beginning-of-line
bindkey '\e[4~' end-of-line
case $TERM in (xterm*)
bindkey '\eOH' beginning-of-line
bindkey '\eOF' end-of-line
esac

#To discover what keycode is being sent, hit ^v
#and then the key you want to test.

#And DEL too, as well as PGDN and insert:
bindkey '\e[3~' delete-char
bindkey '\e[6~' end-of-history
bindkey '\e[2~' redisplay

#Now bind pgup to paste the last word of the last command,
bindkey '\e[5~' insert-last-word
```



## 插件

```shell
# 自动补全
git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

# 高亮
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting

# 修改配置文件
vim ~/.zshrc
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# 重置zsh环境
source ~/.zshrc
```



## 代理

```bash
# 打开配置文件
vim ~/.zshrc

# 在最后一行添加
export ALL_PROXY="socks5://127.0.0.1:7890"
export all_proxy="socks5://127.0.0.1:7890"
export http_proxy="http://127.0.0.1:7890"
export https_proxy="https://127.0.0.1:7890"

#重新加载配置文件
source ~/.zshrc
```



<!-- Q.E.D. -->