---
title: python笔记
katex: true
typora-copy-images-to: ../../img
date: 2021-12-26 22:26:37
updated: 2021-12-26 22:26:37
tags: python
categories: Default
---



<!-- more -->

---

## 运算符重载

> \_\_add\_\_ 和 \__radd__

```python
class Node:
  def __init__(self, num):
    self.n = num
 	
  def __add__(self, other):
    if isinstance(other, Node):
      t = self.n + other.n
    else:
      t = self.n + other
    return t
  
  __radd__ = __add__
```

上面代码通过自定义`__add__`来实现Node对象的加法操作。

其中`__radd__`是为了解决`4 + Node`的情况，首先尝试`(4).__add__(Node)`，返回`NotImplemented`之后，会检查是否定义了`__radd__`，如果定义了就尝试`Node.__radd__(4)`。



> \_\_truediv\_\_ 和\_\_floordiv\_\_

```python
 class Node:
  def __init__(self, num):
    self.n = num
 	
  def __truediv__(self, other): # for /
    if isinstance(other, Node):
      t = self.n / other.n
    else:
      t = self.n / other
    return t

  def __floordiv__(self, other): # for //
    if isinstance(other, Node):
      t = self.n // other.n
    else:
      t = self.n // other
    return t
```





<!-- Q.E.D. -->
