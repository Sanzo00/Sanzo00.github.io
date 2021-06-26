---
title: python环境配置
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-06-25 11:37:14
updated: 2021-06-25 11:37:14
tags:
	- python
	- miniconda
	- venv
categories: Default
---



<!-- more -->

---

## Miniconda

Miniconda是一个轻量级的Conda包管理器

### 安装包

所有安装包：[repo.anaconda.com/miniconda](https://repo.anaconda.com/miniconda/)

Linux: [python3.8 Miniconda3 Linux 64-bit](https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh)

​			[python3.7 Miniconda3 Linux 32-bit](https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86.sh)



### 配置

初始化终端：

```bash
~/miniconda3/bin/conda init
```

如果失败可以手动添加`bin`目录。

```bash
echo "export PATH=\$PATH:/home/pi/miniconda3/bin" >> .bashrc
```



### 使用

> 新建环境

```bash
# 新建名称为test的环境
conda create --name test python=3.8 -y

# arm只能创建python=3.4的环境
conda create -n test python=3.4 -y
```



> 查看所有的环境

```bash
conda env list
```



> 使用环境

```bash
# 激活环境
conda activate test
source activate test # arm

# 退出当前环境
conda deactivate
source deactivate # arm

# 删除环境
conda remove -n test1 --all
```



### rpi

armv7l: [miniconda3-latest-linux-armv7l.sh](https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-armv7l.sh)

[Berryconda3-2.0.0-Linux-armv7l.sh](https://github.com/jjhelmus/berryconda/releases/download/v2.0.0/Berryconda3-2.0.0-Linux-armv7l.sh)

arm版本的miniconda最高只能安装`python3.4`，如果需要安装更高版本的`python`，需要第三方conda，这里使用的是 [berryconda](https://github.com/jjhelmus/berryconda)，目前最高支持到`python3.6`。

```bash
conda config --add channels rpi

conda create --name test python=3.6 -y
```





## venv

python自带的虚拟环境模块

```bash
# 新建
python -m venv /path/venv_name

# 激活
source /path/venv_name/bin/activate

# 退出
deactivate
```



https://www.python.org/ftp/python/3.8.5/Python-3.8.5.tgz



<!-- Q.E.D. -->