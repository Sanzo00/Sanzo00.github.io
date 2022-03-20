---
title: 'c/c++: 函数运行时间'
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-08-22 21:36:25
updated: 2021-08-22 21:36:25
tags:
    - c
    - c++
    - time
categories: Code
---

<!-- more -->

---

## clock()

在C语言中，通常使用`clock()`获取函数执行前后时间，然后除以`CLOCKS_PER_SEC`得到函数运行的时间。

```cpp
#include <time.h>

clock_t start, end;
double cpu_time_used;

start = clock();
... // call function
end = clock();
cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;
```

```cpp
#include <stdio.h>
#include <time.h>

void func() {
  int num = 0;
  for (int i = 0; i < 1e9; ++i) {
    num++;
  }
  return;
}

int main() {

  clock_t start, end;
  double cpu_time_used;

  start = clock();
  func();
  end = clock();
  cpu_time_used = ((double) end - start) / CLOCKS_PER_SEC;

  printf("func() take %.2lfs\n", cpu_time_used); // func() take 2.55s

  return 0;
}
```

## std::chrono()

`std::chrono()`提供两种对象：`timepoint`，`duration`分别对应时间点和间隔。

`chrono()`提供三种时钟：

- `std::chrono::system_clock`：本地系统的当前时间 (可以调整)
- `std::chrono::steady_clock`：不能被调整的，稳定增加的时间
- `std::chrono::high_resolution_clock`：提供最高精度的计时周期 (不同的库实现的可能不一样，不推荐用)

这里使用`steady_clock`来获取当前时间，之后通过`duration`转化为对应的时间单元，例如`nanoseconds`, `microseconds`, `milliseconds,``seconds`, `minutes`, `hours`。

```cpp
auto get_time() { 
  return std::chrono::duration_cast<std::chrono::microseconds> (std::chrono::steady_clock::now().time_since_epoch()).count();
}
```

```cpp
#include <iostream>
#include <chrono>
using namespace std::chrono;

void func() {
  int num = 0;
  for (int i = 0; i < 1e9; ++i) {
    num++;
  }
  return;
}

int main() {

  // get the timepoing before the function is called
  auto start = steady_clock::now();
  func();
  // get the timepoing after the function is called
  auto end = steady_clock::now();

  // get the difference in timepoints and cast to required units
  auto elapsed_us = duration_cast<microseconds> (end - start);
  auto elapsed_s = duration<double> (end - start);
  std::cout << elapsed_us.count() << " " << elapsed_s.count() << std::endl;
  // 2134511 2.13451

  return 0;
}
```

<!-- Q.E.D. -->