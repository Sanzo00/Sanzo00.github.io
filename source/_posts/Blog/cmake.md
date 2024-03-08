---
title: cmake笔记
katex: true
typora-copy-images-to: ..\..\img\default
date: 2021-07-04 22:50:47
updated: 2021-07-04 22:50:47
tags:
	- cmake
categories: Blog
toc: true
---





本文的源代码：[github.com/Sanzo00/cmake-examples](https://github.com/Sanzo00/cmake-examples)

参考项目：[github.com/ttroy50/cmake-examples](https://github.com/ttroy50/cmake-examples/tree/master/)

中文学习地址：[cmake-examples-Chinese](https://sfumecjf.github.io/cmake-examples-Chinese/)

<!-- more -->

## basic

### hello cmake

```bash
.
├── CMakeLists.txt
└── main.cpp
```



```bash
# CMakeLists.txt
# Set the minimum version of CMake that can be used
# To find the cmake version run
# $ cmake --version
cmake_minimum_required(VERSION 3.5)

# Set the project name
project (hello_cmake)

# Add an executable
add_executable(hello_cmake main.cpp)
# add_executable(${PROJECT_NAME} main.cpp)
```

```
message("CMAKE_SOURCE_DIR: ${CMAKE_SOURCE_DIR}")
message("CMAKE_CURRENT_SOURCE_DIR: ${CMAKE_CURRENT_SOURCE_DIR}")
message("PROJECT_SOURCE_DIR: ${PROJECT_SOURCE_DIR}")
message("CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")
message("CMAKE_CURRENT_BINARY_DIR: ${CMAKE_CURRENT_BINARY_DIR}")
message("PROJECT_BINARY_DIR: ${PROJECT_BINARY_DIR}")
```

| Variable                 | Info                         |
| ------------------------ | ---------------------------- |
| CMAKE_SOURCE_DIR         | CMakeLists.txt的根目录       |
| CMAKE_CURRENT_SOURCE_DIR | 当前处理CMakeLists.txt的目录 |
| PROJECT_SOURCE_DIR       | 项目根目录                   |
| CMAKE_BINARY_DIR         | 执行cmake的目录（build）     |
| CMAKE_CURRENT_BINARY_DIR | 当前所在的build目录          |
| PROJECT_BINARY_DIR       | 项目构建的目录               |



### hello headers

```bash
.
├── CMakeLists.txt
├── include
│   └── Hello.h
└── src
    ├── Hello.cpp
    └── main.cpp

```



```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project (hello_headers)

# 创建SOURCES变量，保存所有的源文件
set(SOURCES
  src/Hello.cpp
  src/main.cpp
)

# 创建可执行文件
add_executable(hello_headers ${SOURCES})

# 指定头文件
target_include_directories(${PROJECT_NAME}
  PRIVATE 
  ${PROJECT_SOURCE_DIR}/include
)
```



### static library



```bash
$ tree
.
├── CMakeLists.txt
├── include
│   └── static
│       └── Hello.h
└── src
    ├── Hello.cpp
    └── main.cpp
```



```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(hello_library)

####################################
# Create a library
####################################

add_library(hello_library STATIC
  src/Hello.cpp
)

target_include_directories(hello_library
  PUBLIC
    ${PROJECT_SOURCE_DIR}/include
)

###################################
# Create an executable
###################################
# Add an executable with the above sources
add_executable(hello_binary
  src/main.cpp
)

# link the new hello_library target with the hello_binary target
target_link_libraries( hello_binary
  PRIVATE
    hello_library
)
```



```bash
# 创建静态库文件 libhello_library.a
add_library(hello_library STATIC
  src/Hello.cpp
)
```



### shared library

```bash
$ tree
.
├── CMakeLists.txt
├── include
│   └── shared
│       └── Hello.h
└── src
    ├── Hello.cpp
    └── main.cpp
```



```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(hello_library)

#######################################
# Create a library
#######################################

add_library(hello_library SHARED
  src/Hello.cpp
)

add_library(hello::library ALIAS hello_library)


target_include_directories(hello_library 
  PUBLIC
    ${PROJECT_SOURCE_DIR}/include
)


#######################################
# Create an executable
#######################################

add_executable(hello_binary
  src/main.cpp
)

target_link_libraries(hello_binary PRIVATE
  hello::library
)
```

```bash
# 创建动态库文件 libhello_library.so
add_library(hello_library SHARED
  src/Hello.cpp
)

# 对库起别名为hello:library
add_library(hello::library ALIAS hello_library)
```



### installing

```bash
$ tree
.
├── cmake-examples.conf
├── CMakeLists.txt
├── include
│   └── installing
│       └── Hello.h
├── README.adoc
└── src
    ├── Hello.cpp
    └── main.cpp
```



```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(cmake_install)

############################################
# Create a library
############################################
add_library(cmake_inst SHARED
  src/Hello.cpp
)

target_include_directories(cmake_inst
  PUBLIC
    ${PROJECT_SOURCE_DIR}/include
)

############################################
# Create an executable
############################################
add_executable(cmake_install_bin
  src/main.cpp
)

target_link_libraries(cmake_install_bin 
  PRIVATE
    cmake_inst
)

############################################
# Install
############################################
# Binaries
install(TARGETS cmake_install_bin DESTINATION bin)

# Library
install(TARGETS cmake_inst LIBRARY DESTINATION lib)

# Header files
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/ DESTINATION include)

# Config
install(FILES cmake.conf DESTINATION etc)

# set make install directory
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "The path to use for make install" FORCE)
endif()

# Debug for CMAKE_INSTALL_PREFIX
message("CMAKE_INSTALL_PREFIX: " ${CMAKE_INSTALL_PREFIX})
```



```bash
# 指定make instal的目录为./install
cmake .. -D CMAKE_INSTALL_PREFIX=./install

# 在未指定install目录时，可以在CMakeLists.txt中设置make install的目录
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/install" CACHE PATH "The path to use for make install" FORCE)
endif()

# 在make install也可以通过DESTDIR=/tmp/stage，安装到${DESTDIR}/${CMAKE_INSTALL_PREFIX}
make install DESTDIR=/tmp/stage

# Uninstall
sudo xargs rm < install_manifest.txt
```



### build type

```bash
$ tree
.
├── CMakeLists.txt
├── main.cpp
```



```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)

# Set a default build type if none was specified
# Release, Debug, MinSizeRel, RelWithDebInfo
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message("Setting build type to 'RelWithDebInfo' as none was specified.")
  set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif()

project(build_type)

add_executable(${PROJECT_NAME}
  main.cpp
)
```



Cmake提供四种构建类型：

1. Release，`-O3 -DNDEBUG`
2. Debug，`-g`
3. MinSizeRel，`-Os -DNDEBUG`
4. RelWithDebInfo，`-O2 -g -DNDEBUG`



```bash
# 用户在cmake时指定编译类型
cmake .. -DCMAKE_BUILD_TYPE=Release

# 设置默认的构建类型
# Release, Debug, MinSizeRel, RelWithDebInfo
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message("Setting build type to 'RelWithDebInfo' as none was specified.")
  set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build." FORCE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif()
```



### compile flags

```bash
$ tree
.
├── CMakeLists.txt
├── main.cpp
```

```cpp
// main.cpp
#include <iostream>

int main(int argc, char** argv) {

  std::cout << "Hello Compile Flags!" << std::endl;

// only print if compile flag set
#ifdef EX2
  std::cout << "Hello Compile Flag EX2!" << std::endl;
#endif

#ifdef EX3
  std::cout << "Hello Compile Flag EX3!" << std::endl;
#endif

  return 0;
}
```



```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(compile_flags)

add_executable(${PROJECT_NAME}
  main.cpp
)

# Set a default C++ compile flag
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DEX2" CACHE STRING "Set C++ Compile Flags" FORCE)

target_compile_definitions(${PROJECT_NAME} PRIVATE EX3)
```



```bash
# 为特定的可执行文件或库设置compile flags
target_compile_definitions(${PROJECT_NAME} PRIVATE EX3)

# 设置全局的compile flags
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DEX2" CACHE STRING "Set C++ Compile Flags" FORCE)

# 通过cmake设置
cmake .. -DCMAKE_CXX_FLAGS="-DEX3"
```



### third party library






```bash
# 安装依赖
sudo apt install libboost-system-dev libboost-filesystem-dev
```



```bash
$ tree
.
├── CMakeLists.txt
├── main.cpp
```



```cpp
// main.cpp
#include <iostream>
#include <boost/shared_ptr.hpp>
#include <boost/filesystem.hpp>

int main(int argc, char** argv) {

  std::cout << "Hello Third Party Include!" << std::endl;

  // use a shared ptr
  boost::shared_ptr<int> isp(new int(4));

  // trivial use of boost filesystem
  boost::filesystem::path path = "/usr/share/cmake/modules";
  if (path.is_relative()) {
    std::cout << "Path is relative" << std::endl;
  } else {
    std::cout << "Path is not relative" << std::endl;
  }

  return 0;
}
```



```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(third_party_library)

# find a boost install with the libraries filesystem and system
find_package(Boost 1.46.1 REQUIRED COMPONENTS filesystem system)

# check if boost was found
if(Boost_FOUND)
  message("boost found")
else()
  message(FATAL_ERROR "Cannot find boost")
endif()


add_executable(${PROJECT_NAME}
  main.cpp
)

# link against the boost libraries
target_link_libraries(${PROJECT_NAME}
  PRIVATE
    Boost::filesystem
)
```



> 查找库

```bash
# find package
find_package(Boost 1.46.1 REQUIRED COMPONENTS filesystem system)
```

Boost为库的名称

1.46.1是最低的版本号

REQUIRED表示这是必需的库，如果找不到报错。

COMPONENTS是要查找的库列表



> 检查库是否存在

大多数被包含的库都会设置变量`xxx_FOUND`

```bash
# check if boost was found
if(Boost_FOUND)
  message("boost found")
else()
  message(FATAL_ERROR "Cannot find boost")
endif()
```

如果库存在，一般会设置如下参数用来定位库：

- `xxx_INCLUDE_DIRS` - 头文件位置
- `xxx_LIBRARY` - 库位置



```bash
# Include the boost headers
target_include_directories( third_party_include
    PRIVATE ${Boost_INCLUDE_DIRS}
)

# link against the boost libraries
target_link_libraries( third_party_include
    PRIVATE
    ${Boost_SYSTEM_LIBRARY}
    ${Boost_FILESYSTEM_LIBRARY}
)
```



> 别名

大多数modern CMake库包含别名，例如对于boost来说可以使用：

- `Boost::boost` for header only libraries
- `Boost::system` for the boost system library.
- `Boost::filesystem` for filesystem library.

```bash
target_link_libraries( third_party_include
	PRIVATE
		Boost::filesystem
)
```

### compiling with clang

```bash
# install clang
sudo apt install clang
```





```bash
$ tree
.
├── CMakeLists.txt
├── main.cpp
```

```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(hello_cmake)
add_executable(${PROJECT_NAME} main.cpp)
```



```bash
#!/bin/bash

###################################################
# Delete old build.clang directory
###################################################
ROOT_DIR=`pwd`
#dir="I-compiling-with-clang"

if [ -d "$ROOT_DIR/build.clang" ]; then
  echo "deleting $ROOT_DIR/build.clang"
  rm -rf $ROOT_DIR/build.clang
fi

###################################################
# determine the clang binary before calling cmake
###################################################
clang_bin=`which clang`
clang_xx_bin=`which clang++`

if [ -z $clang_bin ]; then
		# 获取版本号
    clang_ver=`dpkg --get-selections | grep clang | grep -v -m1 libclang | cut -f1 | cut -d '-' -f2`
    clang_bin="clang-$clang_ver"
    clang_xx_bin="clang++-$clang_ver"
fi

echo "Will use clang [$clang_bin] and clang++ [$clang_xx_bin]"

mkdir -p build.clang && cd build.clang && \
  cmake .. -DCMAKE_C_COMPILER=$clang_bin -DCMAKE_CXX_COMPILER=$clang_xx_bin && make
```

CMake的编译器选项：

- CMAKE_C_COMPILER - The program used to compile c code.
- CMAKE_CXX_COMPILER - The program used to compile c++ code.
- CMAKE_LINKER - The program used to link your binary.



### building with ninja

```bash
$ tree
.
├── CMakeLists.txt
├── main.cpp
```

CMake包含多种生成器：`cmake --help`

```bash
Generators

The following generators are available on this platform (* marks default):
* Unix Makefiles               = Generates standard UNIX makefiles.
  Green Hills MULTI            = Generates Green Hills MULTI files
                                 (experimental, work-in-progress).
  Ninja                        = Generates build.ninja files.
  Watcom WMake                 = Generates Watcom WMake makefiles.
  CodeBlocks - Ninja           = Generates CodeBlocks project files.
  CodeBlocks - Unix Makefiles  = Generates CodeBlocks project files.
  CodeLite - Ninja             = Generates CodeLite project files.
  CodeLite - Unix Makefiles    = Generates CodeLite project files.
  Sublime Text 2 - Ninja       = Generates Sublime Text 2 project files.
  Sublime Text 2 - Unix Makefiles
                               = Generates Sublime Text 2 project files.
  Kate - Ninja                 = Generates Kate project files.
  Kate - Unix Makefiles        = Generates Kate project files.
  Eclipse CDT4 - Ninja         = Generates Eclipse CDT 4.0 project files.
  Eclipse CDT4 - Unix Makefiles= Generates Eclipse CDT 4.0 project files.
```

接下来使用Ninja进行构建：

```bash
# install ninja-build
sudo apt install ninja-build

mkdir ninja.build && cd ninja.build

cmake .. -G Ninja

ninja -v
```

### cpp standard

设置c++的编译标准。

```bash
$ tree
.
├── CMakeLists.txt
├── main.cpp
```

```cpp
// main.cpp
#include <iostream>

int main(int argc, char** argv) {

  auto message = "Hello C++11";

  std::cout << message << std::endl;

  return 0;
}
```



```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(hello_cpp11)

# try conditional compilation
include(CheckCXXCompilerFlag) # CHECK_CXX_COMPILER_FLAG的头文件
CHECK_CXX_COMPILER_FLAG("-std=c++11" COMPILER_SUPPORTS_CXX11) # 尝试使用flag进行编译，并把结果保存到变量中
CHECK_CXX_COMPILER_FLAG("-std=c++0x" COMPILER_SUPPORTS_CXX0X)

# check results and add flag
if (COMPILER_SUPPORTS_CXX11)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
elseif(COMPILER_SUPPORTS_CXX0X)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
else()
  message(STATUS "The compiler ${CMAKE_CXX_COMPILER} has no C++11 support. Please use a different C++ compiler.")
endif()

add_executable(${PROJECT_NAME} main.cpp)
```

另外还有两种设置c++ standard的方法：

```bash
#######################################################################
# Using the CMAKE_CXX_STANDARD variable introduced in CMake v3.1.
#######################################################################
set(CMAKE_CXX_STANDARD 11)


#######################################################################
# Using the target_compile_features function introduced in CMake v3.1.
#######################################################################
# set the C++ standard to the appropriate standard for using auto
target_compile_features(hello_cpp11 PUBLIC cxx_auto_type)

# print the list of known compile features for this version of CMake
message("List of compile features: ${CMAKE_CXX_COMPILE_FEATURES}")
```







## sub projects

- sublibrary1 - A static library
- sublibrary2 - A header only library
- subbinary - An executable

```bash
$ tree
.
├── CMakeLists.txt
├── subbinary
│   ├── CMakeLists.txt
│   └── main.cpp
├── sublibrary1
│   ├── CMakeLists.txt
│   ├── include
│   │   └── sublib1
│   │       └── sublib1.h
│   └── src
│       └── sublib1.cpp
└── sublibrary2
    ├── CMakeLists.txt
    └── include
        └── sublib2
            └── sublib2.h
```

```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(sub_projects)

# add sub directories
add_subdirectory(subbinary)
add_subdirectory(sublibrary1)
add_subdirectory(sublibrary2)
```

```bash
# sublibrary1/CMakeLists.txt
# set project name
project(sublibrary1)

# add a library with the above sources
add_library(${PROJECT_NAME} src/sublib1.cpp)
add_library(sub::lib1 ALIAS ${PROJECT_NAME})

target_include_directories(${PROJECT_NAME}
  PUBLIC ${PROJECT_SOURCE_DIR}/include
)
```

```bash
# sublibrary2/CMakeLists.txt
# set the project name
project(sublibrary2)

add_library(${PROJECT_NAME} INTERFACE)
add_library(sub::lib2 ALIAS ${PROJECT_NAME})

target_include_directories(${PROJECT_NAME}
  INTERFACE
    ${PROJECT_SOURCE_DIR}/include
)
```

```bash
# subbinary/CMakeLists.txt
# set project name
project(subbinary)

# create the executable
add_executable(${PROJECT_NAME} main.cpp)

# link the static library from sublibrary1 using it's alias sub::lib1
# link the header only library from sublibrary2 using it's alias sub::lib2
# this will cause the include directories for that target to be added to this project
target_link_libraries(${PROJECT_NAME}
  sub::lib1
  sub::lib2
)
```



## code generation

### configure files

- CMakeLists.txt - Contains the CMake commands you wish to run
- main.cpp - The source file with main
- path.h.in - File to contain a path to the build directory
- ver.h.in - File to contain the version of the project

```bash
$ tree
.
├── CMakeLists.txt
├── main.cpp
├── path.h.in
├── ver.h.in
```

```cpp
// main.cpp
#include <iostream>
#include "ver.h"
#include "path.h"

int main(int argc, char *argv[])
{
    std::cout << "Hello Version " << ver << "!" << std::endl;
    std::cout << "Path is " << path << std::endl;
   return 0;
}
```

通过CMake的`configure_file()`自动生成代码。

```bash
# CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(cf_example)

# set a project version
set(cf_example_VERSION_MAJOR 0)
set(cf_example_VERSION_MINOR 2)
set(cf_example_VERSION_PATCH 1)
set(cf_example_VERSION "${cf_example_VERSION_MAJOR}.${cf_example_VERSION_MINOR}.${cf_example_VERSION_PATCH}")

# call configure files on ver.h to set the version
# uses the standard ${VARIABLE} syntax in the file
configure_file(ver.h.in ${PROJECT_SOURCE_DIR}/ver.h)

# this file can only use the @VARIABLE syntax in the file
configure_file(path.h.in ${PROJECT_SOURCE_DIR}/path.h @ONLY)

add_executable(${PROJECT_NAME} main.cpp)

target_include_directories(${PROJECT_NAME}
  PRIVATE
    ${PROJECT_SOURCE_DIR}
)
```



### protobuf

protobuf是google开源的对字符串进行序列化的库，将要序列化的数据定义写在原始文件`.proto`配置文件中，protobuf将数据序列化为二进制格式，节省内存，加快了数据的传输，但是降低了可读性。

- AddressBook.proto - proto file from main protocol buffer [example](https://developers.google.com/protocol-buffers/docs/cpptutorial)
- CMakeLists.txt - Contains the CMake commands you wish to run
- main.cpp - The source file from the protobuf example.

```bash
$ tree
.
├── AddressBook.proto
├── CMakeLists.txt
├── main.cpp
```

```bash
# CMakeLists.txt
# set cmake minimum version
cmake_minimum_required(VERSION 3.5)

# set the project name
project(protobuf_exmaple)

# find the protobuf compiler and libraries
find_package(Protobuf REQUIRED)

# check if protobuf was found
if (PROTOBUF_FOUND)
  message("protobuf found")
else()
  message(FATAL_ERROR "Cannot find protobuf")
endif()

# generate the .h and .cxx files
PROTOBUF_GENERATE_CPP(PROTO_SRCS PROTO_HDRS AddressBook.proto)

# print path 
message("PROTO_SRCS = ${PROTO_SRCS}")
message("PROTO_HDRS = ${PROTO_HDRS}")

# add an executable
add_executable(${PROJECT_NAME} 
  main.cpp
  ${PROTO_SRCS}
  # ${PROTO_HDRS}  
)

target_include_directories(${PROJECT_NAME}
  PUBLIC
    ${PROTOBUF_INCLUDE_DIRS}
    ${CMAKE_CURRENT_BINARY_DIR}
)

target_link_libraries(${PROJECT_NAME}
  PUBLIC ${PROTOBUF_LIBRARIES}
)
```





<!-- Q.E.D. -->