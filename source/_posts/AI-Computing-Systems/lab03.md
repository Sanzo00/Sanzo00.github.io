---
title: 智能计算系统：实验3
katex: true
typora-copy-images-to: ../../img/
date: 2021-11-07 18:00:42
updated: 2021-11-07 18:00:42
tags:
  - lab
  - mlp
  - vgg19
categories:
  - AI-Computing-Systems
---





<!-- more -->

---



## 预备知识

### 卷积层

![image-20211107224525019](https://img.sanzo.top/img/znjs/image-20211107224525019.png)

打上padding之后的宽和高：

$$H_{pad} = H_{in} + 2p$$

$$W_{pad} = W_{in} + 2p\tag{3.2}$$

输出特征图的高宽：

$$H_{out} = \lfloor \frac{H_{pad}-K}{s} + 1 \rfloor = \lfloor \frac{H_{in}+2p-K}{s} + 1 \rfloor$$

$$ W_{out} = \lfloor \frac{W_{pad}-K}{s} + 1 \rfloor = \lfloor \frac{W_{in} + 2p -K}{s} + 1 \rfloor\tag{3.4}$$

> 前向传播

在边界扩充后的特征图上滑动卷积窗口，计算输出特征图：

<div>
    $$\mathbf{Y}(n, c_{out}, h, w)=\sum_{c_{in}, k_h, k_w} \mathbf{W} (c_{in}, k_h, k_w, c_{out})\mathbf{X}_{pad}(n, c_{in},hs+k_h, ws+k_w) + b(c_{out})\tag{3.3}$$
</div>


> 反向传播

<div>
    $$
    \begin{aligned}
    \nabla_{\mathbf{W}(c_{in},k_h, k_w,c_{out})}L&=\sum_{n,h,w}\nabla_{\mathbf{Y}(n, c_{out},h,w)}L\space\mathbf{X}_{pad}(n, c_{in}, hs+k_h,ws+k_w) \\
    \nabla_{b(c_{out})}L&=\sum_{n,h,w}\nabla_{\mathbf{Y}(n,c_{out},h,w)}L \\
    \nabla_{\mathbf{X}_{pad}(n,c_{in}, hs+i_h,ws+i_w)}L&=\sum_{c_{out}}\sum_{f_h=0}^{\lfloor\frac{K}{s}\rfloor-i_h}\sum_{f_w=0}^{\lfloor\frac{K}{s}-i_w\rfloor}\nabla_{\mathbf{Y}(n,c_{out},h-f_h,w-f_w)}L\space\mathbf{W}(c_{in},f_hs+i_h,f_ws+i_w,c_{out}) \\
    \end{aligned}
    \tag{3.5}
    $$
</div>



<div>$$\nabla_{\mathbf{X}(n,c_{in},h,w)}L=\nabla_{\mathbf{X}_{pad}(n,c_{in},h+p,w+p)}L\tag{3.6}$$</div>

其中$n\in[0,N),\space c_{in}\in[0,C_{in}),\space c_{out}\in[0,C_{out}),\space h\in[0,H_{out}),\space w\in[0,W_{out}),\space k_h\in[0,K),\space k_w\in[0,K),\space i_h\in[0,s),\space i_w\in[0,s)$。



### 最大池化层

> 前向传播

$$Y(n,c,h,w)=\underset{k_h,k_w} {max}\space \mathbf{X}(n,c,hs+k_h,ws+k_w)\tag{3.7}$$



> 反向传播

首先需要计算最大值所在的位置p，其中$F$为获取最大值的函数。

$$p(n,c,h,w)=\underset{k_h,k_w}{F}(\mathbf{X}(n,c,hs+k_h,ws+k_w))\tag{3.8}$$

利用最大值的位置$[q(0), q(1)]$可得最大池化层的$\nabla_{\mathbf{X}}L$：

$$\nabla_{\mathbf{X}(n,c,hs+q(0), ws+q(1))}L=\nabla{\mathbf{Y}(n,c,h,w)}L\tag{3.9}$$







### VGG19

> VGG19网络基本结构

![image-20211107231231715](https://img.sanzo.top/img/znjs/image-20211107231231715.png)



### Img2col

实验中要求对卷积核进行优化，普通的实现是使用4重for循环，所以卷积的计算非常慢。

快速卷积方法有：img2col，Winograd，FFT。

其中Img2col是一种比较好理解的算法，基本思想是将卷积核相乘转化为矩阵相称，很多库已经对矩阵相乘进行了优化，因此速度要比for循环相乘快很多。

关于Img2col的介绍可以参考：

- [High Performance Convolutional Neural Networks for Document Processing](https://hal.inria.fr/file/index/docid/112631/filename/p1038112283956.pdf)
- [卷积神经网络之快速卷积算法(img2col、Winograd、FFT)](https://blog.csdn.net/qq_43409114/article/details/105426806)

{%pdf https://img.sanzo.top/pdf/others/p1038112283956.pdf%}



![image-20211108221620103](https://img.sanzo.top/img/znjs/image-20211108221620103.png)

![image-20211108221653508](https://img.sanzo.top/img/znjs/image-20211108221653508.png)



从下图可以看出，应用Img2col算法，前向传播提高160倍，反向传播提高111倍。

![image-20211108233105519](https://img.sanzo.top/img/znjs/image-20211108233105519.png)







### 非实时风格迁移

![image-20211107231306746](https://img.sanzo.top/img/znjs/image-20211107231306746.png)



> 内容损失函数

$$L_{content} = \frac{1}{2NCHW}\sum_{n,c,h,w}(\mathbf{X}^l(n,c,h,w)-\mathbf{Y}^l(n,c,h,w))^2\tag{3.10}$$

$$\nabla_{\mathbf{X}^l(n,c,h,w)}L_{content}=\frac{1}{NCHW}(\mathbf{X}^l(n,c,h,w)-\mathbf{Y}^l(n,c,h,w))\tag{3.11}$$



> 风格损失函数

在前向传播计算过程中，首先根据Gram矩（Gram可以理解为是特征向量之间的偏心协方差矩阵）计算风格迁移图像和目标风格图像的风格特征G和A。

$$G^l(n,i,j)=\sum_{h,w}\mathbf{X}^l(n,i,h,w)\mathbf{X}^l(n,j,h,w)$$

$$A^l(n,i,j)=\sum_{h,w}\mathbf{Y}^l(n,i,h,w)\mathbf{Y}^l(n,j,h,w)\tag{3.12}$$

风格特征$G^l$和$A^l$的形状为$[N,C,C]$。

$$L_{style}^l=\frac{1}{4NC^2H^2W^2}\sum_{n,i,j}(G^l(n,i,j)-A^l(n,i,j))^2\tag{3.13}$$

$$L_{style}=\sum_{l}\omega_lL_{style}^l\tag{3.14}$$

$$\nabla_{\mathbf{X}^l(n,i,h,w)}L_{style}^l=\frac{1}{NC^2H^2W^2}\sum_{j}\mathbf{X}^l(n,j,h,w)(G^l(n,j,i)-A^l(n,j,i))\tag{3.15}$$



> 损失函数

$$L_{total}=\alpha L_{content}+\beta L_{style}\tag{3.16}$$



> Adam优化器

Adam利用梯度的一阶矩估计和二阶矩估计动态调整每个参数的学习率，因此收敛速度更快，训练过程也更加平稳。

给定待更新风格图像$\mathbf{X}$和梯度$\nabla_{\mathbf{X}}L$，以及当前迭代次数$t$。

Adam超参数$\beta_1=0.9,\beta_2=0.999,\epsilon=10^{-8}$，以及学习率$\eta$。

<div>
$$    
\begin{aligned}
m_t&=\beta_1m_{t-1}+(1-\beta_1)\nabla_{\mathbf{X}}L \\
v_t&=\beta_2v_{t-1}+(1-\beta_2)(\nabla_{\mathbf{X}}L)^2 \\
\hat{m}_t&=\frac{m_t}{1-\beta_1^t} \\
\hat{v}_t&=\frac{v_t}{1-\beta_2^t} \\
\mathbf{X}&\leftarrow\mathbf{X}-\eta\frac{\hat{m}_t}{\sqrt{\hat{v}_t}+\epsilon}
\tag{3.17}
\end{aligned}
$$    
</div>


## 实验补充

1、在实验的代码中，有的地方需要对维度进行变换（代码中有标记），这是因为：

- MatConvNet中的特征图表示形式为：$[N,H,W,C]$，而本实验特征图的形状为$[N,C,H,W]$。
- MatConvNet中的卷积权重表示形式为：$[H,W,C_{in},C_{out}]$，而本实验特征图的形状为$[C_{in},H,W,C_{out}]$。



2.、在第二个实验中，需要从文件中读取VGG19的参数，文件中的权重形状为$[H,W,C_{in},C_{out}]$，而DLP中为$[C_{out}, C_{in}, H, W]$，需要对维度进行变换。

3、在非实时风格迁移中，计算内容损失函数和风格损失函数时，可能会用到中间层的特征图，因此本实验中的前向传播函数会将计算内容/风格损失需要使用的层作为输入参数，利用一个字典记录这些层的输出结果。

4、非实时风格迁移在反向传播过程中与通常的神经网络反向传播过程存在两方面的区别：

- 在反向传播时不需要计算每层的参数梯度，仅需计算每层的损失，用最终得到的第一层的损失作为风格迁移图像的梯度对其进行更新
- 计算内容损失函数和风格损失函数需要用到多个中间层的特征图，而不是只用最后一层的特征图。因此在反向传播的时候首先定位所有计算损失的中间位置，然后从该曾开始逆序前面每一层的损失，最终得到第一层的损失。

## 基于VGG19实现图像分类

实验内容：

1. 利用Python实现VGG19的前向传播计算，加深对VGG19网络结构的理解，为后续风格迁移中使用VGG19网络进行特征提取奠定基础。
2. 在实验2.1基础上将三层神经网络扩展为VGG19网络。

实验工作量：约30行代码，约需3小时。

实验环境：

- 硬件环境：CPU。
- 软件环境：Python编译环境和相关的库，包括Python 2.7、Pillow 6.0.0、SciPy 0.19.0、NumPy 1.16.0。
- 数据集：ImageNet，包括128万张训练图像和5万张测试图像，共有1000个不同的类别。本实验使用官方基于ImageNet数据集训练完成后得到的模型参数，不需要使用ImageNet数据集进行VGG19模型的训练。

```shell
# readme.txt
补全 stu_upload 中的 layer_1.py、layer_2.py、vgg_cpu.py 文件，执行 main_exp_3_1.py 运行实验
```





## 基于DLP平台实现图像分类

实验内容：

1. 使用pycnml库实现卷积、池化等基本网络模块。
2. 使用pycnml库实现VGG19网络。

实验工作量：约40行代码，约需1小时。

实验环境：

- 硬件环境：DLP。
- 软件环境：pycnml，高性能算子库CNML，运行时库CNRT，以及Python相关的库，包括Python 2.7、Pillow 6.00、SciPy 0.19.0、NumPy 1.16.0。
- 数据集：ImageNet

```shell
# readme.txt
补全stu_upload中的 vgg19_demo.py 文件，执行 main_exp_3_2.py 运行实验
```





## 非实时图像风格迁移

实验内容：

1. 使用Python实现风格迁移中风格和内容损失函数的计算，加深对非实时风格迁移的理解。
2. 使用Python语言实现非实时风格迁移中迭代求解风格化图像的完整流程。
3. 完成反向传播的代码以及对前向和反向传播计算的优化。

实验工作量：约20行代码，约需3小时。



```shell
# readme.txt
补全 stu_upload 中的 layer_1.py、layer_2.py、layer_3.py、style_transfer.py 文件，并且补全 main_exp_3_3.py，执行 main_exp_3_3.py 运行实验.
训练生成的图片保存在 output 目录下。
```



<!-- Q.E.D. -->

