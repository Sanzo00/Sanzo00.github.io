---
title: '论文笔记: DeepWalk'
katex: true
typora-copy-images-to: ..\..\img\paper
date: 2021-06-23 22:14:39
updated: 2021-06-23 22:14:39
tags:
categories: Paper
hide: false
---



<!-- more -->

---

[DeepWalk: Online Learning of Social Representations](https://arxiv.org/pdf/1403.6652)

{% pdf https://img.sanzo.top/pdf/paper/1403.6652-deepwalk.pdf %}

[14-KDD-DeepWalk]( https://docs.google.com/presentation/d/1TKRfbtZg_EJFnnzFsnYOsUiyFS0SbNi0X3Qg9OtfDSo)

{% pdf https://docs.google.com/presentation/d/1TKRfbtZg_EJFnnzFsnYOsUiyFS0SbNi0X3Qg9OtfDSo %}



作者首次将深度学习（无监督特征学习）引入到网络分析中，该技术已经在NLP中得到很好的应用，开发出DeepWalk算法，通过对随机游走建模学习图中顶点的隐藏表示。

DeepWalk对图结构的学习独立于标签分布。



## Problem Definition

$G = (V, E)$, 其中$V$是网络的成员，$E$是他的边，$E \in (V \times V)$, 一个带有部分标签的网络可以表示为$G_L = (V,E,X,Y)$，$X \in \mathbf{R} ^ {|V| \times S}$，$S$是特征向量的维度，$Y \in \mathrm{R} ^ {|V| \times |\gamma|}$，$\gamma$是标签的维度。

DeepWalk的目标就是学习到图的隐藏表示$X_E \in \mathrm{R} ^ {|V| \times d}$，$d$是一个很小的维度。



## Language Modeling

社交网络和NLP的词库都遵循着power-law。

![image-20210629122653559](https://img.sanzo.top/img/paper/image-20210629122653559.png)



DeepWalk的主要贡献是将已经用于NLP的技术重新用于网络。

language modeling的目的是估计某个单词序列在语料库中出现的可能性，对于一个单词序列$W_1^n = (w_0,w_1,\cdots,w_n)$，其中$w_i \in V$ (V is vocabulary)，目标是最大化概率$Pr(w_n|w_n,w_1,\cdots,w_{n-1})$，对应在图上的random walk则是最大化$Pr(v_i|v_0,v_1,\cdots,v_{i-1})$，$v_i$是目前为止random walk访问过的节点。

DeepWalk的目标是学习latent representation，引入一个映射函数$\Phi:v\in V \rightarrow \mathrm{R}^{|V| \times d}$，因此目标变为：

![image-20210629122306128](https://img.sanzo.top/img/paper/image-20210629122306128.png)

随着walk length的增加，计算这个目标函数将十分困难，目前在language modeling提出了新的解决方法，将预测任务颠倒过来：

- 不再用上下文预测缺失的单词，而是通过给定单词预测上下文。
- 上下文包含给定单词左右的单词。
- 不考虑单词的顺序，模型最大化上下文中单词出现的概率。

此时优化问题变为：

![image-20210629122255772](https://img.sanzo.top/img/paper/image-20210629122255772.png)



## Algorithm: DeepWalk

DeepWalk算法包含两部分：

- random walk生成器
- 更新程序

![image-20210629121717503](https://img.sanzo.top/img/paper/image-20210629121717503.png)

在每次对所有点进行randowm walk之前，生成一个随机遍历顶点的顺序（line 4），这样可以加快算法收敛的速率。

line 7是按照公示2对representation进行更新。







### SkipGram

![image-20210629122148677](https://img.sanzo.top/img/paper/image-20210629122148677.png)

对于random walk中的每个节点，目标是最大化在窗口$w$中元素的出现的概率，

$\alpha$初始值设置为2.5%，然后线性的减小。

![image-20210629130626818](https://img.sanzo.top/img/paper/image-20210629130626818.png)



### Hierarchical Softmax

使用logistic regression建模，将产生大量等于 $|V|$的标签，是计算变得复杂。

![image-20210629133211810](https://img.sanzo.top/img/paper/image-20210629133211810.png)

如果将顶点放到二叉搜索树的叶子节点，那么预测问题将变为最大化特定路径的概率，节点$u_k$可以表示为$b_0, b_1,\cdots,b_{\lceil log|V| \rceil}$即：

![image-20210629133757732](https://img.sanzo.top/img/paper/image-20210629133757732.png)

使用Haffman编码可以优化访问节点的时间。



### Parallelizability

random walk中的节点的分布遵循power-law，这导致$\Phi$的更新不会很频繁，因此可以使用异步版本的SGD（ASGD），通过多个worker来加速收敛。

![image-20210629134802455](https://img.sanzo.top/img/paper/image-20210629134802455.png)

通过图4可以看出，多个worker可以线性的减少时间，通过对性能的影响非常小。



### Algorithm Variants

> Streaming

流计算将不能获取整张图的信息，因此算法需要进行一些调整：

- 将不再适合使用不断减小的学习率$\alpha$，需要设置为一个足够小的值。
- 因为不知道$|V|$的数量，因此无法构建Hierarchical Softmax tree，可以构造一个足够大的tree，然后不断地将新节点分配到叶子节点，如果可以粗略的估计顶点的访问频率，仍可以使用Haffman编码减少节点访问时间。



> Non-random walks

Some graphs are created as a by-product of agents interacting with a sequence of elements (e.g. users's navigation of pages on a website).

对于这种图可以直接用来建模，以这种方式采样的图不仅捕获了网络结构，同时也得到了遍历路径的频率。



## Experimental

### Multi-label Classification

共使用三种数据集：

![image-20210629140621134](https://img.sanzo.top/img/paper/image-20210629140621134.png)

- BlogCatalog是博客作者的社交关系图，标签表示是作者提供的文章的topic。
- Flicker是照片分享网站中用户之间的联系，标签表示用户的interest group，例如'black and white'。
- Youtube视频分享网站的社交关系图，标签表示喜欢观看视频的类型，例如’anime and wrestling‘。

 和5种算法进行对比：

![image-20210629160520949](https://img.sanzo.top/img/paper/image-20210629160520949.png)





deepwalk的实验参数设置为：$\gamma=80, w=10, d=128$。

> BlogCatalog

算法在BlogCatalog数据集上的表现如下：

![image-20210629175539936](https://img.sanzo.top/img/paper/image-20210629175539936.png)

从图中可以看出，DeepWalk在只有20%数据的情况下，要比很多算法在90%的数据下表现得更好。DeepWalk与SpectralClustering性能很接近，DeepWalk在训练数据稀疏的情况下性能要高于SpectralClustering。

由此可以得出DeepWalk的优势是在数据量很少的情况下也能由很高的准确度，接下来实验主要对比训练数据在10%以下的表现。



> Flickr

![image-20210629175902368](https://img.sanzo.top/img/paper/image-20210629175902368.png)

DeepWalk在训练数据在1%-10%的Flickr上表现比baseline的算法有3%的提升，且在只有3%的训练数据的情况下，比其他算法在10%的表现都要好。





> YouTube

![image-20210629180422404](https://img.sanzo.top/img/paper/image-20210629180422404.png)





### Parameter Sensitivity



> Effect of Dimensionality

![image-20210629181321416](https://img.sanzo.top/img/paper/image-20210629181321416.png)

通过图(a1)和图(a3)对比可以得到，最佳的维度$d$和训练数据的规模有关。

图(a2)和图(a4)是对参数维度$d$和random walk的次数$\gamma$的研究，通过实验可以得到在$\gamma$一定的情况下不同的维度的表现相对稳定，同时又两个有趣的发现：

- BlogCatalog和Flickr都是在$\gamma = 30$时有最好的表现。
- $\gamma$在两个图的相对差异表现一致。

总的来说性能依赖于$\gamma$，维度$d$的选择依赖于训练数据的数量$T_R$。





> Effect of sampling frequency

![image-20210629183629493](https://img.sanzo.top/img/paper/image-20210629183629493.png)



通过上图对比可以看出，$\gamma$在最开始增长对性能的影响很大，当$\gamma > 10$是就变得缓慢了，这个结果也说明了只需要很少次的random walk就可以学习到节点的隐藏表示。



<!-- Q.E.D. --> 