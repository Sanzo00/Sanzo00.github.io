---
title: pybind11简单使用
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-08-02 20:40:30
updated: 2021-08-02 20:40:30
tags: 
	- pybind11
categories: Default
---



<!-- more -->

## pybind11介绍

[github.com/pybind/pybind11](https://github.com/pybind/pybind11)

使用pybind11可以将C++库绑定到Python，即在Python内调用C++代码，同样也可以在C++中调用Python代码。

### 编译安装

```bash
# install pytest
pip install pytest

# install pybind11
git clone https://github.com/pybind/pybind11.git
cd pybind11 && mkdir build && cd build
cmake .. && make && sudo make install
```

接下来使用pybind11演示下如何实现C++调用Python，以及C++调用Python。



## Python调用C++

```cpp
#include <pybind11/pybind11.h>

/***********************调用普通函数***********************/
template <typename T>
T add(T a, T b) {
  return a + b;
}

PYBIND11_MODULE(pyadd, m) {
  m.doc() = "test for add()";
  m.def("add", &add<int>, "add two number.");
  m.def("add", &add<double>, "add two number.");
  m.def("add", &add<long long>, "add two number.");
  m.attr("__version__") = "dev";

  /**
   * >>> import pyadd
   * >>> pyadd.__version__
   * 'dev' 
   * >>> pyadd.add(1.1, 2.2)  
   * 3.3000000000000003 
   */
}

/***********************调用类***********************/
namespace test_class {
class Person {
public:
  Person() {
    name = "Sanzo";
    age = 21;
  }

  Person(std::string name, int age) {
    this->name = name;
    this->age = age;
  }

  std::string getName() {
    return this->name;
  }

  void setName(std::string name) {
    this->name = name;
  }

  int getAge() {
    return age;
  }

  std::string name;

private:
  int age;
};
}

PYBIND11_MODULE(test_class, m) {
  m.doc() = "test_class::person";
  pybind11::class_<test_class::Person>(m, "Person")
    .def(pybind11::init())
    .def(pybind11::init<std::string, int>())
    .def("getAge", &test_class::Person::getAge)
    .def("getName", &test_class::Person::getName)
    .def("setName", &test_class::Person::setName)
    .def_readwrite("name", &test_class::Person::name)
    ;

  /*
      >>> a = test_class.Person()
      >>> a.getName()
      'Sanzo'
      >>> a.getAge()
      21
      >>> a.setName("Sanzo00")
      >>> a.getName()
      'Sanzo00'
      >>> b = test_class.Person("Sazo00", 21)
      >>> b.getName()
      'Sazo00'
      >>> b.getAge()
      21   
  */
}

/***********************调用stl***********************/
#include <pybind11/stl.h>

void printV(std::vector<int> &v) {
  for (auto &it : v) {
    std::cout << it << " ";
  }
  std::cout << std::endl;
}

PYBIND11_MODULE(stl, m) {
  m.doc() = "test for stl.";
  m.def("printV", &printV);

  /*
      >>> import stl
      >>> stl.printV([1, 2, 3, 4])
      1 2 3 4 
  */
}

```



```cmake
// file name: CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(test_pybind)
add_subdirectory(pybind11)
pybind11_add_module(pyadd py_call_cpp.cc)
pybind11_add_module(test_class py_call_cpp.cc)
pybind11_add_module(stl py_call_cpp.cc)
```



## C++调用Python



```cpp
// file name: cpp_call_py.ccc
#include <iostream>
#include <pybind11/pybind11.h>
#include <pybind11/embed.h>

namespace py = pybind11;

int main() {
  py::scoped_interpreter python;
  py::module t = py::module::import("test_add");
  auto result = t.attr("add")(1, 2);
  int sum = result.cast<int>();
  std::cout << "sum = " << sum << std::endl;

  return 0;
}

/*
    vim ~/.bashrc # 将工作目录添加到环境变量中
    export PYTHONPATH=/home/ubuntu/test_pybind:$PATH
*/
```



```python
// file name: test_add.py
def add(a, b):
  print(f"add({a}, {b})")
  return a + b
```



```cmake
// file name: CMakeLists.txt
cmake_minimum_required(VERSION 3.5)
project(test_pybind)
add_subdirectory(pybind11)

add_executable(cpp_call_py cpp_call_py.cc test_add.py)

target_include_directories(cpp_call_py
  PUBLIC
  /usr/include/python3.8
)

target_link_libraries(cpp_call_py
  PUBLIC
  /home/ubuntu/miniconda3/lib/libpython3.8.so
)
```



## 注意

1. 需要将`pybind11`放到工作目录下
2. C++调用python时，需要将当前工作目录添加到环境变量`PYTHONPATH`中，这样python就可以找到自定义的包。



<!-- Q.E.D. -->