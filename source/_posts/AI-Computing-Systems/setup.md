---
title: 智能计算系统：实验环境配置
katex: true
typora-copy-images-to: ../../img/
date: 2021-10-31 11:37:14
updated: 2021-10-31 11:37:14
tags:
	- setup
categories: AI-Computing-Systems
---



<!-- more -->

## 注册登录

[寒武纪开发平台: devplatform.cambricon.com:30080](http://devplatform.cambricon.com:30080/)

首先注册帐号：

![image-20211031104939174](https://img.sanzo.top/img/znjs/image-20211031104939174.png)

登录后的界面如下：

![image-20211031104725603](https://img.sanzo.top/img/znjs/image-20211031104725603.png)



## 创建存储卷

1. 点击左侧菜单栏选择**存储管理**，点击右上角**添加存储卷**。
2. 填写存储卷的名称和大小。



![image-20211031105532919](https://img.sanzo.top/img/znjs/image-20211031105532919.png)



![image-20211031110101449](https://img.sanzo.top/img/znjs/image-20211031110101449.png)



![image-20211031110140532](https://img.sanzo.top/img/znjs/image-20211031110140532.png)







## 创建开发容器

1. 点击左侧栏开发容器，点击右上角添加开发容器；
2. 填写开发容器名称、用户名，选择镜像、规格、并挂载存储卷到对应路径；

注意事项：

- 用户名root ，切勿改成其他的
- 密码尽可能设置的复杂一些，也可以不设置系统会随机生成12位的口令
- 镜像：`public-server/mlu270_ubuntu16.04-for-student-1.4.0`
- 标签选择对应的章节（v2、v3...）
- 规格：《智能计算系统 2.0 》上课规格
- 存储卷挂载路径：/workspace 或 /home/姓名



![image-20211031112745493](https://img.sanzo.top/img/znjs/image-20211031112745493.png)



![image-20211031112758041](https://img.sanzo.top/img/znjs/image-20211031112758041.png)



![image-20211031112909663](https://img.sanzo.top/img/znjs/image-20211031112909663.png)







## 登录开发容器

进入开发容器详情页，查看IP、端口号、密码

![image-20211031112943428](https://img.sanzo.top/img/znjs/image-20211031112943428.png)



SSH工具：[XShell](https://www.netsarang.com/en/xshell/)、[MobaXterm](https://mobaxterm.mobatek.net/download-home-edition.html)、shell

 `ssh root@ip -p 端口号`

![image-20211031125835406](https://img.sanzo.top/img/znjs/image-20211031125835406.png)



## 编辑器

大家可以使用`vim`或者`vscode`来写代码。

> vscode

首先安装`Remote-ssh`插件。

![image-20211031131058777](https://img.sanzo.top/img/znjs/image-20211031131058777.png)



添加远程主机。

```shell
Host chap2
    HostName 120.236.247.203
    User root
    Port 22088
```

![image-20211031131525684](https://img.sanzo.top/img/znjs/image-20211031131525684.png)



实验的代码在opt目录下：

![image-20211031131823233](https://img.sanzo.top/img/znjs/image-20211031131823233.png)







## 注意事项

- 容器被删除或重置了，数据丢失是找不回来的，所以无比及时保存重要文件到存储卷路径下。
- 开发容器一直处于创建中的状态，可能是因为：
  - 集群资源不足，无可用的MLU卡。
  - 存储卷挂在到了根目录`\`下。



<!-- Q.E.D. -->

