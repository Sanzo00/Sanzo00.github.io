---
title: >-
  PowerLore: Distributed Power-law Graph Computing Theoretical and Empirical
  Analysis
hidden: false
katex: true
typora-copy-images-to: https://img.sanzo.top/img/paper
sticky: 0
date: 2022-04-08 21:45:16
updated: 2022-04-08 21:45:16
tags:
categories:
---



<!-- more -->

---

PowerLore NIPS'14: [paper](https://cx2.web.engr.illinois.edu/papers/powerlore.pdf) [code](https://github.com/xcgoner/powerlore)

{%pdf https://cx2.web.engr.illinois.edu/papers/powerlore.pdf %}



PowerLore是一个高效的处理power-law图的分布式框架。

主要的贡献是：

- degree-based hashing algorithm (Libra)，提供了理论证明。
- two degree-based greedy algorithm (Constell and Zodiac)



## Graph Partition

现有的图分区可以归并为两类：vetex-cut和edge-cut。

> Edge-cut

Edge-cut tries to evenly assign vetices to machines bu cutting edge. Both machines of a cut edge should maintain a ghost (local replica) of the vertex and the edge data. 

The workload of a machine is determined by the number of vetices located in that machine.

The communication cost of the whole graph is determined by the number of edges spanning different machines.



> Vetex-cut

Vetex-cut tries to evenly assign the edges to machines bu cutting the vertices. All the machines associated with a cut vetex should maintain a mirror (local replica) of the vertex. 

The workload of a machine is determind by the number of edges located in that machine.

The communication cost of the whole graph is determined by the number of mirrors of the vertices.

![image-20220408220640066](https://img.sanzo.top/img/paper/image-20220408220640066.png)



传统的分布式图计算框架GraphLab，Pregel使用edge-cut的划分方法，PowerGraph发现vetex-cut可以实现更好的性能，尤其是在Power-law图上。



![image-20220408221207144](https://img.sanzo.top/img/paper/image-20220408221207144.png)



图2a是一个power-law graph的例子，图2b是切点{E, F, A, C, D}，图2c是切点{A, E}，相比图2b是更好的划分，因为他的通信量更少。

直觉告诉我们切高度顶点可以产生更少的顶点，因此power-law的度数分配可以用来解决划分问题。

现有的框架PowerGraph和graph Builder没有使用度数分布来指导分区，powerLyra使用度数分区来混合edge-cut和vetex-cut但是缺少理论保证。



## Power-Law

现实生活中的大图的度数分布符合power laws：$Pr(d) \propto d^{-\alpha}$，$Pr(d)$是节点度数为d的概率。

下图是Twitter-2010社交网络的度数分布，$\alpha \approx 2$。

![image-20220408224715317](https://img.sanzo.top/img/paper/image-20220408224715317.png)



## Degree-based Hasing Algorithm



用idx区分不同的机器。Libra应用两个hash函数来完成顶点和边的划分：

顶点划分：$idx=vetex\_hash(v_i) \in [p]$。

边划分：$idx=edge\_hash(v_i, v_j) \in [p]$。

其中顶点划分采用随机的hash函数，保证节点分配到每个分区的概率一样，对于边来划分比较重要，因为边决定了workload以及通信的开销。

Libra使用$vetex\_hash$函数来定义$edge\_hash$，将边分给度数小的点所在的分区。(We name this algorithm by Libra, because it weighs the degrees of the two ends of each edge, which behaves like a pair of scales)。



![image-20220408231744751](https://img.sanzo.top/img/paper/image-20220408231744751.png)

![image-20220408232022401](https://img.sanzo.top/img/paper/image-20220408232022401.png)



## Constel

![image-20220409145113001](https://img.sanzo.top/img/paper/image-20220409145113001.png)



## Zodiac

![image-20220409145059835](https://img.sanzo.top/img/paper/image-20220409145059835.png)



<!-- Q.E.D. -->
