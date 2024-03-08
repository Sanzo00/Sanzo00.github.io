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
- pytorch
- setup
categories: Blog
toc: true
---



python相关环境配置：Miniconda，PyTroch，Jupyter， venv。



<!-- more -->









## Miniconda

Miniconda是一个轻量级的Conda包管理器

### 安装包

所有安装包：[repo.anaconda.com/miniconda](https://repo.anaconda.com/miniconda/)

Linux: [python3.8 Miniconda3 Linux 64-bit](https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh)

​			[python3.7 Miniconda3 Linux 32-bit](https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86.sh)

```bash
# 以前的版本没有ssh问题
wget https://repo.anaconda.com/miniconda/Miniconda3-4.7.12.1-Linux-x86_64.sh
```



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



## Pytorch

old version lib torch: [https://github.com/pytorch/pytorch/issues/40961](https://github.com/pytorch/pytorch/issues/40961)

[Pytorch](https://pytorch.org/get-started/locally/)，选择对应cuda版本。

```shell
torch.version # PyTorch version
torch.cuda.is_available()
torch.version.cuda # Corresponding CUDA version
torch.backends.cudnn.version() # Corresponding cuDNN version
torch.cuda.get_device_name(0) # GPU type
```



### build



```bash
# install pytorch and dependences
git clone --depth 1 --recurse-submodule https://github.com/pytorch/pytorch.git
conda create -y --name pytorch-build python=3.8
conda activate pytorch-build
conda install -y astunparse numpy ninja pyyaml mkl mkl-include setuptools cmake cffi typing_extensions future six requests dataclasses pkg-config libuv

# arm64
mkdir pytorch-build-arm64
cd pytorch-build-arm64
cmake -DBUILD_SHARED_LIBS:BOOL=ON -DCMAKE_OSX_ARCHITECTURES=arm64 DCMAKE_OSX_DEPLOYMENT_TARGET=12.10 -DUSE_MKLDNN=OFF -DUSE_QNNPACK=OFF -DUSE_PYTORCH_QNNPACK=OFF -DBUILD_TEST=OFF -DUSE_NNPACK=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DPYTHON_EXECUTABLE:PATH=`which python3` -DCMAKE_INSTALL_PREFIX:PATH=../pytorch-install-arm64 ../pytorch
cmake --build . --target install
cd ..

# x86_64
mkdir pytorch-build-x86_64
cd pytorch-build-x86_64
cmake -DBUILD_SHARED_LIBS:BOOL=ON -DCMAKE_OSX_ARCHITECTURES=x86_64 -DCMAKE_OSX_DEPLOYMENT_TARGET=12.10 -DUSE_MKLDNN=OFF -DUSE_QNNPACK=OFF -DUSE_PYTORCH_QNNPACK=OFF -DBUILD_TEST=OFF -DUSE_NNPACK=OFF -DCMAKE_BUILD_TYPE:STRING=Release -DPYTHON_EXECUTABLE:PATH=`which python3` -DCMAKE_INSTALL_PREFIX:PATH=../pytorch-install-x86_64 ../pytorch
cmake --build . --target install
cd ..
```





### test



```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(example-app)

set(Torch_DIR /Users/sanzo/Software/pytorch-install-arm64)
set(CMAKE_PREFIX_PATH "/Users/sanzo/Software/pytorch-install-arm64/share/cmake/Torch")
find_package(Torch REQUIRED)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${TORCH_CXX_FLAGS}")

add_executable(example-app example-app.cpp)
target_link_libraries(example-app "${TORCH_LIBRARIES}")
set_property(TARGET example-app PROPERTY CXX_STANDARD 14)
```



```cpp
#include <torch/torch.h>
#include <iostream>

int main() {
  std::cout << "PyTorch version: "
    << TORCH_VERSION_MAJOR << "."
    << TORCH_VERSION_MINOR << "."
    << TORCH_VERSION_PATCH << std::endl;
  torch::Tensor tensor = torch::rand({2, 3});
  std::cout << tensor << std::endl;
}

/*
 0.0598  0.7058  0.0322
 0.2230  0.4112  0.9342
[ CPUFloatType{2,3} ]
*/
```









> references

old version lib torch: [https://github.com/pytorch/pytorch/issues/40961](https://github.com/pytorch/pytorch/issues/40961)

https://dev-discuss.pytorch.org/t/universal-binaries-for-libtorch-mac/229

https://github.com/pytorch/pytorch/issues/63558









## jupyter notebook

### ipykernel

通过ipykernel管理jupyter notebook的内核。

```bash
# 激活环境
activate env_name

# 安装ipykernel
pip install ipykernel

# 添加kernel
python -m ipykernel install --name env_name

# 删除内核
jupyter kernelspec remove kernelname

# 查看所有内核
jupyter kernelspec list
```



### 远程访问

生成密钥

```bash
# 通过ipython生成密码
ipython

In [1]: from notebook.auth import passwd
In [2]: passwd()
Enter password: 
Verify password: 
Out[3]: 'xxxxxxxxxxxxxxxxxxxxxx'

# 生成配置文件，并添加如下配置
jupyter notebook --generate-config

c.NotebookApp.ip='0.0.0.0'
c.NotebookApp.password = u'xxxxxxxxxxxxxxxxxxxxxx'
c.NotebookApp.open_browser = False
c.NotebookApp.port =8888
```

然后就可以通过`https://ip:8888`远程访问`jupyter notebook`









<!-- Q.E.D. -->

