---
title: Pytorch编译
hidden: false
katex: true
typora-copy-images-to: ../../img
date: 2022-01-25 19:28:42
updated: 2022-01-25 19:28:42
tags:
  - python
  - pytorch
  - libtorch
  - compile
categories: Default
---



<!-- more -->

---



## compile libtorch

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





## test

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









## references

old version lib torch: [https://github.com/pytorch/pytorch/issues/40961](https://github.com/pytorch/pytorch/issues/40961)

https://dev-discuss.pytorch.org/t/universal-binaries-for-libtorch-mac/229

https://github.com/pytorch/pytorch/issues/63558



<!-- Q.E.D. -->
