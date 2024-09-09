---
title: 'yabai: macOS的窗口管理'
katex: true
sticky: 0
toc: true
typora-copy-images-to: ../../img
date: 2024-07-14 15:25:56
updated: 2024-07-14 15:25:56
tags:
categories:
---

自动分屏

<!-- more -->


cite: [How To Setup And Use The Yabai Tiling Window Manager On Mac](https://www.josean.com/posts/yabai-setup)

## setup

```bash
# install yabai
brew install koekeishiya/formulae/yabai
yabai --start-service
yabai --restart-service

# install skhd
brew install koekeishiya/formulae/skhd
skhd --start-service
skhd --restart-service

mkdir ~/.config/yabai
cd ~/.config/yabai
wget https://raw.githubusercontent.com/Sanzo00/config/main/yabai/yabairc

mkdir ~/.config/skhd
cd ~/.config
wget https://raw.githubusercontent.com/Sanzo00/config/main/skhd/skhdrc
```



## command

| Function              | Shortcuts                   |
| --------------------- | --------------------------- |
| Focus within space    | Alt + (H, J, K, L)          |
| Focus between display | Alt + (W, E)                |
| Toggle window float   | Shift + Alt + F             |
| Maximize window       | Alt + M                     |
| Balance  layout       | Alt + B                     |
| Swap window           | Shift  + Alt + (H, J, K, L) |
|                       |                             |

