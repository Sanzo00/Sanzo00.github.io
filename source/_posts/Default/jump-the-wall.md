---
title: Jump the Wall
hidden: false
katex: true
sticky: 0
typora-copy-images-to: ../../img
date: 2022-05-19 11:13:08
updated: 2022-05-19 11:13:08
tags: v2ray
categories: Default
---



<!-- more -->

---



## V2ray



### 服务端

测试ip：[ping.chinaz.com](https://ping.chinaz.com)

证书申请：https://freessl.cn/

```bash
#X-ui面板安装
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)


# ufw开启端口
ufw allow 40000:60000/tcp
ufw allow 40000:60000/udp
```



### 客户端

Android，linux，macOS 安装包：https://github.com/v2fly/v2ray-core/releases

v2ray客户端配置文件：https://github.com/Sanzo00/files/blob/master/other/v2ray.json

linux端下载v2ray安装包之后，可以选择安装到本地或者直接运行可执行文件。

> 安装到本地

```bash
wget https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
# 自动选择安装包
sudo bash install-release.sh

# 指定安装包
sudo bash install-release.sh --local ./v2ray-linux-64.zip

# 将配置文件拷贝到 /usr/local/etc/v2ray/config.json
```



> 直接运行可执行文件

```bash
nohup ./v2ray run config.json > v2ray.log 2>&1 &
```



## 代理设置



### 终端代理

```bash
export ALL_PROXY="socks5://127.0.0.1:10800"
export all_proxy="socks5://127.0.0.1:10800"
export http_proxy="http://127.0.0.1:10801"
export https_proxy="https://127.0.0.1:10801"
```



### git代理

> 对http和https代理

```bash
# http and https
git config --global http.proxy http://127.0.0.1:10801
git config --global https.proxy https://127.0.0.1:10801

# socks5
git config --global http.proxy socks5://127.0.0.1:10800
git config --global https.proxy socks5://127.0.0.1:10800

# unset
git config --global --unset http.proxy
git config --global --unset https.proxy
```



> 对ssh代理：

```bash
sudo apt install connect-proxy
vim ~/.ssh/config

# socks5
Host github.com
User git
ProxyCommand connect -S 127.0.0.1:10800 %h %p

# http || https
Host github.com
User git
ProxyCommand connect -H 127.0.0.1:10801 %h %p
```





<!-- Q.E.D. -->
