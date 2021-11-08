---
title: 智能计算系统：实验2
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-10-31 19:59:42
updated: 2021-10-31 19:59:42
tags:
  - lab
  - mlp
categories:
  - AI-Computing-Systems
---



<!-- more -->

---

## 预备知识

以下所有公式的输入均为矩阵（批量数据）。

>  前向传播

输入$\mathbf{X}$为一个批量数据大小为（p，m），权重矩阵$\mathbf{W}$大小为（m，n），偏置$\mathbf{b}$大小为（n，1）。

$$\mathbf{Y}=\mathbf{X}\mathbf{W}+\mathbf{b}^{T}$$



> 反向传播

假设已知Loss对$\mathbf{Y}$的梯度$\nabla_{\mathbf{Y}}L$，那么Loss对X、W、b的梯度可以通过下式得到：

$$\nabla_{\mathbf{W}}L=\mathbf{X}^T\nabla_{\mathbf{Y}}L$$

$$\nabla_{\mathbf{b}}L={(\nabla_{\mathbf{Y}}L})^T\mathbf{1}$$

$$\nabla_{\mathbf{X}}L=\nabla_{\mathbf{Y}}L\mathbf{W}^T$$

其中$\mathbf{1}$为p维全1向量。

> ReLU函数

ReLU函数的计算公式为：

$$y(i)=max(0,x(i))$$

偏导：

<div>$$\nabla_{x(i)}L \left\{ \begin{array}{rcl} \nabla_{y(i)}L & x(i)\ge 0 \\ 0 & x(i)<0 \end{array}\right.$$</div>

**注意ReLU的偏导是针对输入的正负进行判断的。**

> Softmax函数



Softmax损失计算：

$$\hat{\mathbf{Y}}(i, j)=\frac{e^{\mathbf{X}(i,j)}}{\sum_{j}e^{\mathbf{X}(i,j)}}$$

对e指数进行减最大值操作，防止数值上溢。

$$\hat{\mathbf{Y}}(i, j)=\frac{e^{\mathbf{X}(i,j)-\underset{n}{max}\space\mathbf{X}(i,n)}}{\sum_{j}e^{\mathbf{X}(i,j)-\underset{n}{max}\space\mathbf{X}(i,n)}}$$





> 交叉熵

损失函数L：

$$L=-\frac{1}{p}\sum_{i,j}\mathbf{Y}(i,j)ln\hat{\mathbf{Y}}(i,j)$$

偏导：

$$\nabla_{\mathbf{X}}L=\frac{1}{p}(\hat{\mathbf{Y}} - \mathbf{Y})$$



> 梯度更新

$$\mathbf{W}\leftarrow \mathbf{W} - \eta\nabla_{\mathbf{W}}L$$





## 基于三层神经网络实现手写数字分类

实验内容：

1. 实现三层神经网络模型进行手写数字分类，建立一个简单而完整的神经网络工程，通过本实验理解神经网络中基本模块的作用和模块间的关系，为后续建立更复杂的神经网络（如风格迁移）奠定基础。
2. 利用Python实现神经网络基本单元的前向传播和反向传播计算，加深对神经网络中基本单元（全连接层、激活函数、损失函数等）的理解。
3. 利用Python实现神经网络训练中所使用的梯度下降算法，加强对神经网络训练过程的理解。

实验工作量：约20行代码，约需2小时。



```shell
# readme.txt
补全 stu_upload 中的 layer_1.py、mnist_mlp_cpu.py 文件，执行 main_exp_2_1.py 运行实验
```



## 基于DLP平台实现手写数字分类

实验内容：

1. 利用pycnml库中的Python接口搭建用于手写数字分类的三层神经网络。
2. 熟悉在DLP上运行神经网络的流程。

实验工作量：约10行代码，约需1小时。

```shell
# readme.txt
补全 stu_upload 中的 mnist_mlp_demo.py 文件, 并复制实验2-1中实现的layer_1.py、mnist_mlp_cpu.py 以及训练得到的参数复制到 stu_upload 目录下，执行 main_exp_2_2.py 运行实验。

注意：
上传的实验2-1中训练生成的模型参数，如 mlp-32-16-10epoch.npy，需要修改名称为 weight.npy，否则无法识别。
上传的 mnist mlp 网络的 cpu 实现，即实验2-1中完成的 mnist_mlp_cpu.py 文件，需要做出以下修改：

修改 build_mnist_mlp() 函数中的内容：
1.  修改 batch_size.
    将 mlp = MNIST_MLP(hidden1=h1, hidden2=h2, max_epoch=e) 
    修改为 mlp = MNIST_MLP(batch_size=10000, hidden1=h1, hidden2=h2, max_epoch=e)

2.  注释掉训练的函数
    mlp.train()
    和
    mlp.save_model('mlp-%d-%d-%depoch.npy' % (h1, h2, e))
    两句，并将
    mlp.load_model('mlp-%d-%d-%depoch.npy' % (h1, h2, e))
    取消注释，同时修改函数参数为 param_dir
    mlp.load_model(param_dir)
```




<!-- Q.E.D. -->

