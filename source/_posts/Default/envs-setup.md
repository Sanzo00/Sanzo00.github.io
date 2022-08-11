---
title: 各种环境配置
hidden: false
katex: true
typora-copy-images-to: ../../img
date: 2022-02-23 14:31:21
updated: 2022-02-23 14:31:21
tags: 
  - linux
  - python
  - software
  - envs
  - setup
categories: Default
---



<!-- more -->

---

记录一些用到的环境配置。

## cmake

https://cmake.org/download/

```bash
# install and extract
wget https://github.com/Kitware/CMake/releases/download/v3.22.2/cmake-3.22.2.tar.gz
tar xzvf cmake-3.22.2

# uninstall old version
sudo apt autoremove cmake

# make and install
cd cmake-3.22.2.tar.gz
./bootstrap
make -j16
sudo make install
```



## mpich

```bash
# download your mpich version
https://www.mpich.org/static/downloads/3.2.1/

# decompress
tar -xzvf mpich-3.2.1.tar.gz

# make and install
./configure --disable-fortran --prefix=/home/software/mpich
make -j8
make install
```





## PyG

官方下载链接：https://pytorch-geometric.readthedocs.io/en/latest/notes/installation.html

>  M1 Mac

https://github.com/rusty1s/pytorch_scatter/issues/241

```bash
MACOSX_DEPLOYMENT_TARGET=12.3 CC=clang CXX=clang++ python -m pip --no-cache-dir   install torch torchvision torchaudio

python -c "import torch; print(torch.__version__)"  #---> (Confirm the version is 1.11.0)

MACOSX_DEPLOYMENT_TARGET=12.3 CC=clang CXX=clang++ python -m pip --no-cache-dir  install  torch-scatter -f https://data.pyg.org/whl/torch-1.11.0+${cpu}.html

MACOSX_DEPLOYMENT_TARGET=12.3 CC=clang CXX=clang++ python -m pip --no-cache-dir  install  torch-sparse -f https://data.pyg.org/whl/torch-1.11.0+${cpu}.html

MACOSX_DEPLOYMENT_TARGET=12.3 CC=clang CXX=clang++ python -m pip --no-cache-dir  install  torch-geometric
```







<!-- Q.E.D. -->
