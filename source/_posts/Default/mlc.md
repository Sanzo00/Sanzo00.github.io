---
title: 机器学习编译（持续更新中...）
hidden: false
katex: true
sticky: 0
typora-copy-images-to: ../../img/default/mlc
date: 2022-08-11 14:29:51
updated: 2022-08-11 14:29:51
tags:
	- ML
	- compile
categories: Default
---



<!-- more -->

---

中文笔记：https://mlc.ai/zh/

中文课表：https://mlc.ai/summer22-zh/schedule

课程代码：https://github.com/mlc-ai/notebooks

课后作业：https://github.com/Sanzo00/mlc-summer22



## 机器学习编译概述

机器学习模型的开发到部署存在很多复杂的变量：硬件（ARM 或 x86）、操作系统、容器执行环境、运行时计算库 (Runtime Libraries) 或所涉及的加速器类型的问题。

![image-20220811144805632](../../img/default/mlc/image-20220811144805632.png)







机器学习编译（machine learning compilation，MLC）：将机器学习算法从开发阶段，通过变换和优化算法，使其变成部署阶段。



机器学习编译不同于传统的编译，首先机器学习编译不一定涉及代码生成，例如，部署形式可以是一组预定义的库函数，ML编译只需要将开发阶段转换为对这些函数的调用。另外遇到的挑战和解决方案也不同。



> MLC 目标

机器学习编译的目标：

1. 集成与最小化依赖，代码集成和最小化依赖可以减小应用的大小，并且可以使应用程序部署到更多的环境。
2. 利用硬件加速，每个部署环境都有自己的一套原生加速技术，并且其中许多都是专门为机器学习开发的，机器学习编译的一个目标就是利用硬件本身的特性进行加速。具体可以通过构建调用原生加速库的部署代码或者利用原生指令的代码来实现。
3. 通用优化：以最小化内存使用和提高效率的方式转化模型执行。







> 关键要素

机器学习编译的关键要素：张量（Tensor），张量函数（Tensor Functions）

机器学习编译的过程就是将下图左侧的内容转化为右侧的内容，在不同的场景下这个过程可以是人工，也可以是一些自动转换工具，或者二者都有。

![image-20220811151701724](../../img/default/mlc/image-20220811151701724.png)





> 抽象和实现

MLC实际上是在相同或不同抽象下，转换和组装张量函数的过程，研究张量函数不同的抽象类型，以及他们是如何协同工作的。

![image-20220811152107534](../../img/default/mlc/image-20220811152107534.png)





## 张量程序抽象

> 元张量函数

元张量函数表示机器学习模型中单个单元计算，例如`relu`,`linear`,`softmax`等。



张量程序抽象包含：

- 存储数据的多维数组
- 驱动张量计算的循环嵌套
- 计算部分本身

![image-20220811180018801](../../img/default/mlc/image-20220811180018801.png)



张量程序中的额外结构可以为程序变换提供更多的信息。

![image-20220811180133212](../../img/default/mlc/image-20220811180133212.png)



> 总结

- 元张量函数表示机器学习模型计算中的单个单元计算。
  - 一个机器学习编译过程可以有选择地转换元张量函数的实现。
- 张量程序是一个表示元张量函数的有效抽象。
  - 关键成分包括: 多维数组，循环嵌套，计算语句。
  - 程序变换可以被用于加速张量程序的执行。
  - 张量程序中额外的结构能够为程序变换提供更多的信息。



## TensorIR

```python
import numpy as np
import tvm
from tvm.ir.module import IRModule
from tvm.script import tir as T
```


> TensorIR



TensorIR是开源机器学习框架Apache TVM中使用的张量程序抽象。

下面以`mm_relu`函数举例：

这段代码是使用低级numpy实现的：

```python
def lnumpy_mm_relu(A: np.ndarray, B: np.ndarray, C: np.ndarray):
    Y = np.empty((128, 128), dtype="float32")
    for i in range(128):
        for j in range(128):
            for k in range(128):
                if k == 0:
                    Y[i, j] = 0
                Y[i, j] = Y[i, j] + A[i, k] * B[k, j]
    for i in range(128):
        for j in range(128):
            C[i, j] = max(Y[i, j], 0)
```



下面代码是使用TVMScript 的语言实现的，它是一种嵌入在 Python AST 中的特定领域方言。

```python
@tvm.script.ir_module
class MyModule:
    @T.prim_func
    def mm_relu(A: T.Buffer[(128, 128), "float32"],
                B: T.Buffer[(128, 128), "float32"],
                C: T.Buffer[(128, 128), "float32"]):
        T.func_attr({"global_symbol": "mm_relu", "tir.noalias": True})
        Y = T.alloc_buffer((128, 128), dtype="float32")
        for i, j, k in T.grid(128, 128, 128):
            with T.block("Y"):
                vi = T.axis.spatial(128, i)
                vj = T.axis.spatial(128, j)
                vk = T.axis.reduce(128, k)
                with T.init():
                    Y[vi, vj] = T.float32(0)
                Y[vi, vj] = Y[vi, vj] + A[vi, vk] * B[vk, vj]
        for i, j in T.grid(128, 128):
            with T.block("C"):
                vi = T.axis.spatial(128, i)
                vj = T.axis.spatial(128, j)
                C[vi, vj] = T.max(Y[vi, vj], T.float32(0))
```



其中`T.grid`是TensorIR中的语法糖，用来写多个嵌套的迭代器。

`T.block`是TensorIR中的基本计算单元，一个块包含了一组块轴`(vi, vj,vk)`和围绕他们的计算。



```python
vi = T.axis.spatial(128, i)
vj = T.axis.spatial(128, j)
vk = T.axis.reduce(128, k)

[block_axis] = T.axis.[axis_type]([axis_range], [mapped_value])
```



一个块轴包含以下信息：

- 定义了 `vi`、`vj`、`vk` 应被绑定到的位置（在本例中为 `i`、`j` 和 `k`）；
- 声明了 `vi`、`vj`、`vk` 的原始范围（`T.axis.spatial(128, i)` 中的 `128`）；
- 声明了块轴的属性（`spatial`, `reduce`）。



块轴的语法糖：`T.axis.remap`

```python
# SSR means the properties of each axes are "spatial", "spatial", "reduce"
vi, vj, vk = T.axis.remap("SSR", [i, j, k])

# 等价于

vi = T.axis.spatial(range_of_i, i)
vj = T.axis.spatial(range_of_j, j)
vk = T.axis.reduce(range_of_k, k)
```





> 变换

TensorIR 引入了一个名为 Schedule 的辅助结构帮助我们做程序变换。

原始的MyModule：

```python
@tvm.script.ir_module
class Module:
    @T.prim_func
    def mm_relu(A: T.Buffer[(128, 128), "float32"], B: T.Buffer[(128, 128), "float32"], C: T.Buffer[(128, 128), "float32"]) -> None:
        # function attr dict
        T.func_attr({"global_symbol": "mm_relu", "tir.noalias": True})
        # body
        # with T.block("root")
        Y = T.alloc_buffer([128, 128], dtype="float32")
        for i, j, k in T.grid(128, 128, 128):
            with T.block("Y"):
                vi, vj, vk = T.axis.remap("SSR", [i, j, k])
                T.reads(A[vi, vk], B[vk, vj])
                T.writes(Y[vi, vj])
                with T.init():
                    Y[vi, vj] = T.float32(0)
                Y[vi, vj] = Y[vi, vj] + A[vi, vk] * B[vk, vj]
        for i, j in T.grid(128, 128):
            with T.block("C"):
                vi, vj = T.axis.remap("SS", [i, j])
                T.reads(Y[vi, vj])
                T.writes(C[vi, vj])
                C[vi, vj] = T.max(Y[vi, vj], T.float32(0))
```





创建一个以给定的 MyModule 作为输入的 Schedule 辅助类，并获得对块 Y 和相应循环的引用

```python
sch = tvm.tir.Schedule(MyModule)

block_Y = sch.get_block("Y", func_name="mm_relu")
i, j, k = sch.get_loops(block_Y)
```



循环 j 分成两个循环，其中内部循环的长度为 4


```python
j0, j1 = sch.split(j, factors=[None, 4])
```




```python
@tvm.script.ir_module
class Module:
    @T.prim_func
    def mm_relu(A: T.Buffer[(128, 128), "float32"], B: T.Buffer[(128, 128), "float32"], C: T.Buffer[(128, 128), "float32"]) -> None:
        # function attr dict
        T.func_attr({"global_symbol": "mm_relu", "tir.noalias": True})
        # body
        # with T.block("root")
        Y = T.alloc_buffer([128, 128], dtype="float32")
        for i, j_0, j_1, k in T.grid(128, 32, 4, 128):
            with T.block("Y"):
                vi = T.axis.spatial(128, i)
                vj = T.axis.spatial(128, j_0 * 4 + j_1)
                vk = T.axis.reduce(128, k)
                T.reads(A[vi, vk], B[vk, vj])
                T.writes(Y[vi, vj])
                with T.init():
                    Y[vi, vj] = T.float32(0)
                Y[vi, vj] = Y[vi, vj] + A[vi, vk] * B[vk, vj]
        for i, j in T.grid(128, 128):
            with T.block("C"):
                vi, vj = T.axis.remap("SS", [i, j])
                T.reads(Y[vi, vj])
                T.writes(C[vi, vj])
                C[vi, vj] = T.max(Y[vi, vj], T.float32(0))
```



重新排序这两个循环

```python
sch.reorder(j0, k, j1)
```



```python
@tvm.script.ir_module
class Module:
    @T.prim_func
    def mm_relu(A: T.Buffer[(128, 128), "float32"], B: T.Buffer[(128, 128), "float32"], C: T.Buffer[(128, 128), "float32"]) -> None:
        # function attr dict
        T.func_attr({"global_symbol": "mm_relu", "tir.noalias": True})
        # body
        # with T.block("root")
        Y = T.alloc_buffer([128, 128], dtype="float32")
        for i, j_0, k, j_1 in T.grid(128, 32, 128, 4):
            with T.block("Y"):
                vi = T.axis.spatial(128, i)
                vj = T.axis.spatial(128, j_0 * 4 + j_1)
                vk = T.axis.reduce(128, k)
                T.reads(A[vi, vk], B[vk, vj])
                T.writes(Y[vi, vj])
                with T.init():
                    Y[vi, vj] = T.float32(0)
                Y[vi, vj] = Y[vi, vj] + A[vi, vk] * B[vk, vj]
        for i, j in T.grid(128, 128):
            with T.block("C"):
                vi, vj = T.axis.remap("SS", [i, j])
                T.reads(Y[vi, vj])
                T.writes(C[vi, vj])
                C[vi, vj] = T.max(Y[vi, vj], T.float32(0))

```





将块 C 移动到 Y 的内循环

```python
block_C = sch.get_block("C", "mm_relu")
sch.reverse_compute_at(block_C, j0)
```


```python
@tvm.script.ir_module
class Module:
    @T.prim_func
    def mm_relu(A: T.Buffer[(128, 128), "float32"], B: T.Buffer[(128, 128), "float32"], C: T.Buffer[(128, 128), "float32"]) -> None:
        # function attr dict
        T.func_attr({"global_symbol": "mm_relu", "tir.noalias": True})
        # body
        # with T.block("root")
        Y = T.alloc_buffer([128, 128], dtype="float32")
        for i, j_0 in T.grid(128, 32):
            for k, j_1 in T.grid(128, 4):
                with T.block("Y"):
                    vi = T.axis.spatial(128, i)
                    vj = T.axis.spatial(128, j_0 * 4 + j_1)
                    vk = T.axis.reduce(128, k)
                    T.reads(A[vi, vk], B[vk, vj])
                    T.writes(Y[vi, vj])
                    with T.init():
                        Y[vi, vj] = T.float32(0)
                    Y[vi, vj] = Y[vi, vj] + A[vi, vk] * B[vk, vj]
            for ax0 in T.serial(4):
                with T.block("C"):
                    vi = T.axis.spatial(128, i)
                    vj = T.axis.spatial(128, j_0 * 4 + ax0)
                    T.reads(Y[vi, vj])
                    T.writes(C[vi, vj])
                    C[vi, vj] = T.max(Y[vi, vj], T.float32(0))
```


将 Y 元素的初始化与归约更新分开

```python
sch.decompose_reduction(block_Y, k)
```

```python
@tvm.script.ir_module
class Module:
    @tir.prim_func
    def mm_relu(A: tir.Buffer[(128, 128), "float32"], B: tir.Buffer[(128, 128), "float32"], C: tir.Buffer[(128, 128), "float32"]) -> None:
        # function attr dict
        tir.func_attr({"global_symbol": "mm_relu", "tir.noalias": True})
        # body
        # with tir.block("root")
        Y = tir.alloc_buffer([128, 128], dtype="float32")
        for i, j_0 in tir.grid(128, 32):
            for j_1_init in tir.serial(4):
                with tir.block("Y_init"):
                    vi = tir.axis.spatial(128, i)
                    vj = tir.axis.spatial(128, j_0 * 4 + j_1_init)
                    tir.reads()
                    tir.writes(Y[vi, vj])
                    Y[vi, vj] = tir.float32(0)
            for k, j_1 in tir.grid(128, 4):
                with tir.block("Y_update"):
                    vi = tir.axis.spatial(128, i)
                    vj = tir.axis.spatial(128, j_0 * 4 + j_1)
                    vk = tir.axis.reduce(128, k)
                    tir.reads(Y[vi, vj], A[vi, vk], B[vk, vj])
                    tir.writes(Y[vi, vj])
                    Y[vi, vj] = Y[vi, vj] + A[vi, vk] * B[vk, vj]
            for ax0 in tir.serial(4):
                with tir.block("C"):
                    vi = tir.axis.spatial(128, i)
                    vj = tir.axis.spatial(128, j_0 * 4 + ax0)
                    tir.reads(Y[vi, vj])
                    tir.writes(C[vi, vj])
                    C[vi, vj] = tir.max(Y[vi, vj], tir.float32(0))
```


运行IRModule中得到的程序。

```python
# 调用构建函数将 IRModule 变换为 runtime.Module
rt_lib = tvm.build(MyModule, target="llvm")

# 创建三个用于保存输入和输出的 TVM NDArray
a_nd = tvm.nd.array(a_np)
b_nd = tvm.nd.array(b_np)
c_nd = tvm.nd.empty((128, 128), dtype="float32")

# 从 rt_lib 中获取可运行函数, 通过传递三个数组参数来执行它
func_mm_relu = rt_lib["mm_relu"]
func_mm_relu(a_nd, b_nd, c_nd)

np.testing.assert_allclose(c_mm_relu, c_nd.numpy(), rtol=1e-5)
```



性能对比：

```python
f_timer_before = rt_lib.time_evaluator("mm_relu", tvm.cpu())
print("Time cost of MyModule %g sec" % f_timer_before(a_nd, b_nd, c_nd).mean)
f_timer_after = rt_lib_after.time_evaluator("mm_relu", tvm.cpu())
print("Time cost of transformed sch.mod %g sec" % f_timer_after(a_nd, b_nd, c_nd).mean)
```

```bash
Time cost of MyModule 0.00330733 sec
Time cost of transformed sch.mod 0.00113919 sec
```

性能差距的原因跟CPU的缓存特性有一定的关系，CPU带有多级缓存，需要先将数据提取到缓冲中，CPU才能访问它，特别的访问已经在缓存中的数据要快得多。CPU采用cache line的策略，一次加载相邻的数据到缓存中。

![image-20220811190250728](../../img/default/mlc/image-20220811190250728.png)



而程序变换得到的代码，对j1的迭代产生了对B元素的连续访问，另外使 `C` 的计算更接近 `Y`，从而实现更好的缓存行为。

![image-20220811190418974](../../img/default/mlc/image-20220811190418974.png)



> 创建TensorIR的方式

我们可以通过，TVM Sccipt和张量表达式来创建TensorIR。

张量表达式 (TE) 是一种特定领域的语言，它通过 API 之类的表达式描述一系列计算。



```python
from tvm import te

A = te.placeholder((128, 128), "float32", name="A")
B = te.placeholder((128, 128), "float32", name="B")
k = te.reduce_axis((0, 128), "k")
Y = te.compute((128, 128), lambda i, j: te.sum(A[i, k] * B[k, j], axis=k), name="Y")
C = te.compute((128, 128), lambda i, j: te.max(Y[i, j], 0), name="C")
```

`te.compute` 采用签名 `te.compute(output_shape, fcompute)`。 `fcompute` 函数描述了对于给定的索引 `(i, j)` 我们要如何计算元素 `Y[i, j]` 的值。

```python
lambda i, j: te.sum(A[i, k] * B[k, j], axis=k)
```



创建一个具有两个输入参数（A，B）和一个输出参数（C）的函数

```python
te_func = te.create_prim_func([A, B, C]).with_attr({"global_symbol": "mm_relu"})
MyModuleFromTE = tvm.IRModule({"mm_relu": te_func})
```



```python
@tvm.script.ir_module
class Module:
    @T.prim_func
    def mm_relu(A: T.Buffer[(128, 128), "float32"], B: T.Buffer[(128, 128), "float32"], C: T.Buffer[(128, 128), "float32"]) -> None:
        # function attr dict
        T.func_attr({"global_symbol": "mm_relu", "tir.noalias": True})
        # body
        # with T.block("root")
        Y = T.alloc_buffer([128, 128], dtype="float32")
        for i0, i1, i2 in T.grid(128, 128, 128):
            with T.block("Y"):
                i, j, k = T.axis.remap("SSR", [i0, i1, i2])
                T.reads(A[i, k], B[k, j])
                T.writes(Y[i, j])
                with T.init():
                    Y[i, j] = T.float32(0)
                Y[i, j] = Y[i, j] + A[i, k] * B[k, j]
        for i0, i1 in T.grid(128, 128):
            with T.block("C"):
                i, j = T.axis.remap("SS", [i0, i1])
                T.reads(Y[i, j])
                T.writes(C[i, j])
                C[i, j] = T.max(Y[i, j], T.float32(0))
```





MLC流程：开发、变换、构建。

![image-20220811203120513](../../img/default/mlc/image-20220811203120513.png)





[2.4 TensorIR: 张量程序抽象案例研究.](https://github.com/Sanzo00/mlc-summer22/blob/master/2.4_case-study.ipynb)

[2.5 TensorIR 练习](https://github.com/Sanzo00/mlc-summer22/blob/master/2.5_tensorir-exercises.ipynb)



> 总结

- TensorIR 抽象
  - 包含循环、多维缓冲区等常用元素
  - 引入了一个封装循环计算要求的新结构**块**。
  - 可以在 Python AST 中构建（通过 TVMScript）
- 我们可以使用变换来创建不同的 TensorIR 变体。
- 通用 MLC 流程：开发、变换、构建。





## 端到端模型整合

以一个简单的模型为例子：

![image-20220814222435282](../../img/default/mlc/image-20220814222435282.png)



在TVMScript中构建端到端的IRModule：

```python
@tvm.script.ir_module
class MyModule:
    @T.prim_func
    def relu0(X: T.Buffer[(1, 128), "float32"],
              Y: T.Buffer[(1, 128), "float32"]):
        # function attr dict
        T.func_attr({"global_symbol": "relu0", "tir.noalias": True})
        for i, j in T.grid(1, 128):
            with T.block("Y"):
                vi, vj = T.axis.remap("SS", [i, j])
                Y[vi, vj] = T.max(X[vi, vj], T.float32(0))

    @T.prim_func
    def linear0(X: T.Buffer[(1, 784), "float32"],
                W: T.Buffer[(128, 784), "float32"],
                B: T.Buffer[(128,), "float32"],
                Z: T.Buffer[(1, 128), "float32"]):
        T.func_attr({"global_symbol": "linear0", "tir.noalias": True})
        Y = T.alloc_buffer((1, 128), "float32")
        for i, j, k in T.grid(1, 128, 784):
            with T.block("Y"):
                vi, vj, vk = T.axis.remap("SSR", [i, j, k])
                with T.init():
                    Y[vi, vj] = T.float32(0)
                Y[vi, vj] = Y[vi, vj] + X[vi, vk] * W[vj, vk]

        for i, j in T.grid(1, 128):
            with T.block("Z"):
                vi, vj = T.axis.remap("SS", [i, j])
                Z[vi, vj] =  Y[vi, vj] + B[vj]

    @T.prim_func
    def linear1(X: T.Buffer[(1, 128), "float32"],
                W: T.Buffer[(10, 128), "float32"],
                B: T.Buffer[(10,), "float32"],
                Z: T.Buffer[(1, 10), "float32"]):
        T.func_attr({"global_symbol": "linear1", "tir.noalias": True})
        Y = T.alloc_buffer((1, 10), "float32")
        for i, j, k in T.grid(1, 10, 128):
            with T.block("Y"):
                vi, vj, vk = T.axis.remap("SSR", [i, j, k])
                with T.init():
                    Y[vi, vj] = T.float32(0)
                Y[vi, vj] = Y[vi, vj] + X[vi, vk] * W[vj, vk]

        for i, j in T.grid(1, 10):
            with T.block("Z"):
                vi, vj = T.axis.remap("SS", [i, j])
                Z[vi, vj] = Y[vi, vj] + B[vj]

    @R.function
    def main(x: Tensor((1, 784), "float32"),
             w0: Tensor((128, 784), "float32"),
             b0: Tensor((128,), "float32"),
             w1: Tensor((10, 128), "float32"),
             b1: Tensor((10,), "float32")):
        with R.dataflow():
            lv0 = R.call_tir(linear0, (x, w0, b0), (1, 128), dtype="float32")
            lv1 = R.call_tir(relu0, (lv0,), (1, 128), dtype="float32")
            out = R.call_tir(linear1, (lv1, w1, b1), (1, 10), dtype="float32")
            R.output(out)
        return out
```



和之前不同的是，这里的IRModule有个新的函数，R.function，他是一个Relax函数，表示上层神经网络执行的全新抽象。



下面这个图是使用计算图表示模型执行的过程：

![image-20220814222849062](../../img/default/mlc/image-20220814222849062.png)



> R.call_tir

计算图中的每一个操作都包含一个R.call_tir操作。

```python
lv0 = R.call_tir(linear0, (x, w0, b0), (1, 128), dtype="float32")
```



和R.call_tir对应的numpy实现为：

```python
def lnumpy_call_tir(prim_func, inputs, shape, dtype):
    res = np.empty(shape, dtype=dtype)
    prim_func(*inputs, res)
    return res
```

简单来说，cal_tir接受一个元函数（prim_func）的输入列表，分配一个输出张量res，然后将输入和输出传递给prim_func，执行prim_func之后，结果填充到res，然后返回结果。

这种规定称为**目标传递（destination passing）**，将输入和输出在外部显示的分配并传递给底层元函数，这种风格通常用于底层库的实现，并不是所有的函数都可以写成这种形式，例如一些操作的输出形状取决于输入。这样写的一个好处是可以让高层框架处理内存分配。

当然也可以通过显示的分配中间结果并调用每个函数讲目标传递的函数组装在一起，但是很难将以下代码转换为计算图。

```python
def lnumpy_mlp(data, w0, b0, w1, b1):
    lv0 = np.empty((1, 128), dtype="float32")
    lnumpy_linear0(data, w0, b0, lv0)

    lv1 = np.empty((1, 128), dtype="float32")
    lnumpy_relu0(lv0, lv1)

    out = np.empty((1, 10), dtype="float32")
    lnumpy_linear1(lv1, w1, b1, out)
    return out
```



![image-20220814223828564](../../img/default/mlc/image-20220814223828564.png)



call_tir的关键思想是想要隐藏可能的分配或对函数的显式写入。 用更正式的术语来说，我们希望函数是 **pure** 或 **side-effect free**。



> Dataflow Block



```python
with R.dataflow():
    lv0 = R.call_tir(linear0, (x, w0, b0), (1, 128), dtype="float32")
    lv1 = R.call_tir(relu0, (lv0,), (1, 128), dtype="float32")
    out = R.call_tir(linear1, (lv1, w1, b1), (1, 10), dtype="float32")
    R.output(out)
```

dataflow block是标记程序计算图区域的一种方式，在dataflow block中，所有操作都需要side-effect free。 在dataflow block之外，操作可能包含side-effect。 下面的程序是一个包含两个dataflow block的示例程序。

```python
@R.function
def main(x: Tensor((1, 784), "float32"),
         w0: Tensor((128, 784), "float32"),
         b0: Tensor((128,), "float32"),
         w1: Tensor((10, 128), "float32"),
         b1: Tensor((10,), "float32")):

    with R.dataflow():
        lv0 = R.call_tir(linear0, (x, w0, b0), (1, 128), dtype="float32")
        gv0 = R.call_tir(relu0, (lv0,), (1, 128), dtype="float32")
        R.output(gv0)

    gv1 = R.alloc_tensor((1, 128), dtype="float32")

    with R.dataflow():
        out = R.call_tir(linear1, (gv0, gv1, b0), (1, 128), dtype="float32")
        R.output(out)
    return out
```



> 模型构建

build 函数会给我们一个可执行文件（是针对Relax VM设计的一种文件格式）。

```python
ex = relax.vm.build(MyModule, target="llvm")
type(ex)
```



初始化一个虚拟机执行器

```python
vm = relax.VirtualMachine(ex, tvm.cpu())
```



构建输入和权重数组

```python
data_nd = tvm.nd.array(img.reshape(1, 784))
nd_params = {k: tvm.nd.array(v) for k, v in mlp_params.items()}
```



传入输入参数和权重来运行 `main` 函数

```python
nd_res = vm["main"](data_nd,
                    nd_params["w0"],
                    nd_params["b0"],
                    nd_params["w1"],
                    nd_params["b1"])
print(nd_res)
```



> 集成现有的运行库

```python
@tvm.script.ir_module
class MyModuleWithExternCall:
    @R.function
    def main(x: Tensor((1, 784), "float32"),
             w0: Tensor((128, 784), "float32"),
             b0: Tensor((128,), "float32"),
             w1: Tensor((10, 128), "float32"),
             b1: Tensor((10,), "float32")):
        # block 0
        with R.dataflow():
            lv0 = R.call_tir("env.linear", (x, w0, b0), (1, 128), dtype="float32")
            lv1 = R.call_tir("env.relu", (lv0,), (1, 128), dtype="float32")
            out = R.call_tir("env.linear", (lv1, w1, b1), (1, 10), dtype="float32")
            R.output(out)
        return out
```



注册相应的函数:

```python
@tvm.register_func("env.linear", override=True)
def torch_linear(x: tvm.nd.NDArray,
                 w: tvm.nd.NDArray,
                 b: tvm.nd.NDArray,
                 out: tvm.nd.NDArray):
    x_torch = torch.from_dlpack(x)
    w_torch = torch.from_dlpack(w)
    b_torch = torch.from_dlpack(b)
    out_torch = torch.from_dlpack(out)
    torch.mm(x_torch, w_torch.T, out=out_torch)
    torch.add(out_torch, b_torch, out=out_torch)

@tvm.register_func("env.relu", override=True)
def lnumpy_relu(x: tvm.nd.NDArray,
                out: tvm.nd.NDArray):
    x_torch = torch.from_dlpack(x)
    out_torch = torch.from_dlpack(out)
    torch.maximum(x_torch, torch.Tensor([0.0]), out=out_torch)
```



在上面的代码中，我们使用 `from_dlpack` 将 TVM NDArray 转换为 torch NDArray。 请注意，这是一个零拷贝转换，这意味着 Torch 阵列与 TVM NDArray 共享底层内存。 DLPack 是一种通用的交换标准，允许不同的框架交换 Tensor/NDArray 而无需参与数据复制



构建运行：

```python
ex = relax.vm.build(MyModuleWithExternCall, target="llvm")
vm = relax.VirtualMachine(ex, tvm.cpu())

nd_res = vm["main"](data_nd,
                    nd_params["w0"],
                    nd_params["b0"],
                    nd_params["w1"],
                    nd_params["b1"])

pred_kind = np.argmax(nd_res.numpy(), axis=1)
print("MyModuleWithExternCall Prediction:", class_names[pred_kind[0]])
```



另外TensorIR也支持混合的表示形式：

```python
@tvm.script.ir_module
class MyModuleMixture:
    @T.prim_func
    def linear0(X: T.Buffer[(1, 784), "float32"],
                W: T.Buffer[(128, 784), "float32"],
                B: T.Buffer[(128,), "float32"],
                Z: T.Buffer[(1, 128), "float32"]):
        T.func_attr({"global_symbol": "linear0", "tir.noalias": True})
        Y = T.alloc_buffer((1, 128), "float32")
        for i, j, k in T.grid(1, 128, 784):
            with T.block("Y"):
                vi, vj, vk = T.axis.remap("SSR", [i, j, k])
                with T.init():
                    Y[vi, vj] = T.float32(0)
                Y[vi, vj] = Y[vi, vj] + X[vi, vk] * W[vj, vk]

        for i, j in T.grid(1, 128):
            with T.block("Z"):
                vi, vj = T.axis.remap("SS", [i, j])
                Z[vi, vj] =  Y[vi, vj] + B[vj]

    @R.function
    def main(x: Tensor((1, 784), "float32"),
             w0: Tensor((128, 784), "float32"),
             b0: Tensor((128,), "float32"),
             w1: Tensor((10, 128), "float32"),
             b1: Tensor((10,), "float32")):
        with R.dataflow():
            lv0 = R.call_tir(linear0, (x, w0, b0), (1, 128), dtype="float32")
            lv1 = R.call_tir("env.relu", (lv0,), (1, 128), dtype="float32")
            out = R.call_tir("env.linear", (lv1, w1, b1), (1, 10), dtype="float32")
            R.output(out)
        return out
```





> 绑定参数



在许多情况下，将参数绑定为附加到 IRModule 的常量通常会降低API的复杂程度。 以下代码通过将参数名称与 nd_params 中的键匹配来创建绑定。

```python
MyModuleWithParams = relax.transform.BindParams("main", nd_params)(MyModuleMixture)
IPython.display.Code(MyModuleWithParams.script(), language="python")
```



`meta[relay.Constant][0]`  对应于一个存储常量的隐式字典：

```python
@tvm.script.ir_module
class Module:
    @R.function
    def main(x: Tensor((1, 784), "float32")) -> Tensor(None, "float32", ndim = 2):
        # block 0
        with R.dataflow():
            lv0 = R.call_tir(linear0, (x, meta[relay.Constant][0], meta[relay.Constant][1]), (1, 128), dtype="float32")
            lv1 = R.call_tir("env.relu", (lv0,), (1, 128), dtype="float32")
            out = R.call_tir("env.linear", (lv1, meta[relay.Constant][2], meta[relay.Constant][3]), (1, 10), dtype="float32")
            R.output(out)
        return out

    @T.prim_func
    def linear0(X: T.Buffer[(1, 784), "float32"], W: T.Buffer[(128, 784), "float32"], B: T.Buffer[128, "float32"], Z: T.Buffer[(1, 128), "float32"]) -> None:
        # function attr dict
        T.func_attr({"global_symbol": "linear0", "tir.noalias": True})
        # body
        # with T.block("root")
        Y = T.alloc_buffer([1, 128], dtype="float32")
        for i, j, k in T.grid(1, 128, 784):
            with T.block("Y"):
                vi, vj, vk = T.axis.remap("SSR", [i, j, k])
                T.reads(X[vi, vk], W[vj, vk])
                T.writes(Y[vi, vj])
                with T.init():
                    Y[vi, vj] = T.float32(0)
                Y[vi, vj] = Y[vi, vj] + X[vi, vk] * W[vj, vk]
        for i, j in T.grid(1, 128):
            with T.block("Z"):
                vi, vj = T.axis.remap("SS", [i, j])
                T.reads(Y[vi, vj], B[vj])
                T.writes(Z[vi, vj])
                Z[vi, vj] = Y[vi, vj] + B[vj]
```



现在可以通过传入输入数据来调用该函数:

```python
ex = relax.vm.build(MyModuleWithParams, target="llvm")
vm = relax.VirtualMachine(ex, tvm.cpu())

nd_res = vm["main"](data_nd)

pred_kind = np.argmax(nd_res.numpy(), axis=1)
print("MyModuleWithParams Prediction:", class_names[pred_kind[0]])
```



> 总结

- 计算图抽象有助于将元张量函数拼接在一起以进行端到端执行。
- Relax 抽象的关键要素包括
  - call_tir 构造，将目标传递规范的元函数嵌入到计算图中
  - Dataflow block
- 计算图允许调用环境库函数和 `TensorIR` 函数。



[MLC 作业 1: 端到端模型执行](https://github.com/Sanzo00/mlc-summer22/blob/master/assignment1_zh.ipynb)



## 自动化程序优化

https://mlc.ai/zh/chapter_auto_program_optimization/index.html







## 与机器学习框架整合











## GPU硬件加速



https://github.com/NVIDIA/cutlass/blob/master/media/docs/efficient_gemm.md





## 计算图优化：算子融合和内存优化









## 部署模型到服务环境









## 部署模型到边缘设备





<!-- Q.E.D. -->
