---
title: ubuntu配置
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-10-08 09:52:47
updated: 2021-10-08 09:52:47
tags: 
  - ubuntu
  - setup
categories: Linux
---



<!-- more -->

## 代理

> 配置v2ray

[v2ray-core/releases](https://github.com/v2fly/v2ray-core/releases)

```shell
mkdir v2ray && cd v2ray
wget https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
sudo bash install-release.sh --local ./v2ray-linux-64.zip
```

```shell
# 参考配置文件
{
  "inbounds": [ 
    {
      "tag": "proxy",
      "port": 10800,
      "listen": "127.0.0.1",
      "protocol": "socks",
      ...
    },
    {
      "tag": "proxy-http",
      "port": 10801,
      "listen": "127.0.0.1",
      "protocol": "http",
      ...
    }
  ],
    "outbounds": [
        {
        	...
        }
    ]
}
```

![image-20211008182055367](https://img.sanzo.top/img/linux/image-20211008182055367.png)



> proxychains

```shell
sudo apt install proxychains

# 修改配置文件
sudo vim /etc/proxychains.conf 
# 最后一行改为对应自己的端口
socks5    127.0.0.1 10800
```



> apt代理

```shell
sudo vim /etc/apt/apt.conf.d/proxy.conf
Acquire::http::Proxy "socks5h://127.0.0.1:10800";
Acquire::https::Proxy "socks5h://127.0.0.1:10800";
```



> bash代理

```shell
vim ~/.bashrc
# vim ~/.zshrc

export ALL_PROXY="socks5://127.0.0.1:10800"
export all_proxy="socks5://127.0.0.1:10800"
export http_proxy="http://127.0.0.1:10801"
export https_proxy="https://127.0.0.1:10801"
```

在setting中设置了http，apt和bash应该可以不用再设置了，以防万一可以加上。





## vim

```shell
sudo apt install vim

# 添加配置文件
vim ~/.vimrc

"set paste
"set nopaste
set expandtab
set softtabstop=2
set autoindent
set tabstop=2
set shiftwidth=2
set nu
syntax on
set mouse=a "支持鼠标滑轮
set mouse=v "支持鼠标选中复制
"set viminfo='1000,<500
```



## git

```shell
sudo apt install git

# 环境配置
git config --global user.email "arrangeman@163.com"
git config --global user.name "Sanzo00"
git config --global http.proxy 'socks5://127.0.0.1:10800'
git config --global https.proxy 'socks5://127.0.0.1:10800'

# 生成公钥和私钥
ssh-keygen -t rsa -C "your_email@example.com"

# 将公钥放到github中
cat ~/.ssh/id_rsa.pub 
```



## 鼠标

> 修改滑轮速度

[IMWheel](https://wiki.archlinux.org/title/IMWheel#Run_IMWheel_on_startup_using_a_service)

```shell
sudo apt install imwheel
sudo vim ~/.imwheelrc

".*"
None,      Up,   Button4, 5 # 速度
None,      Down, Button5, 5 # 速度
Control_L, Up,   Control_L|Button4
Control_L, Down, Control_L|Button5
Shift_L,   Up,   Shift_L|Button4
Shift_L,   Down, Shift_L|Button5
```



> 开机自启

```shell
sudo ~/.config/systemd/user
vim ~/.config/systemd/user/imwheel.service

[Unit]
Description=IMWheel
Wants=display-manager.service
After=display-manager.service

[Service]
Type=simple
Environment=XAUTHORITY=%h/.Xauthority
ExecStart=/usr/bin/imwheel -d
ExecStop=/usr/bin/pkill imwheel
RemainAfterExit=yes

[Install]
WantedBy=graphical-session.target

systemctl --user daemon-reload
systemctl --user enable --now imwheel.service
journalctl --user --unit imwheel.service
```





## 网速监控

```shell
sudo add-apt-repository ppa:fossfreedom/indicator-sysmonitor -y
sudo apt update
sudo apt-get install indicator-sysmonitor

# 运行
indicator-sysmonitor
```

![image-20211008181906389](https://img.sanzo.top/img/linux/image-20211008181906389.png)

![image-20211008181800153](https://img.sanzo.top/img/linux/image-20211008181800153.png)



## 截图

我在windows[snipaste](https://www.snipaste.com/)，不过linux还没出，先用ubuntu默认的截图吧。

- `PrtSc` – 获取整个屏幕的截图并保存到 Pictures 目录。
- `Shift + PrtSc` – 获取屏幕的某个区域截图并保存到 Pictures 目录。
- `Alt + PrtSc` –获取当前窗口的截图并保存到 Pictures 目录。
- `Ctrl + PrtSc` – 获取整个屏幕的截图并存放到剪贴板。
- `Shift + Ctrl + PrtSc` – 获取屏幕的某个区域截图并存放到剪贴板。
- `Ctrl + Alt + PrtSc` – 获取当前窗口的 截图并存放到剪贴板。



## 其他

[typora](https://typora.io/#linux)



<!-- Q.E.D. -->

