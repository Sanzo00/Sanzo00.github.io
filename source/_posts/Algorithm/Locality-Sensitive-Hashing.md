---
title: Locality Sensitive Hashing
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-10-01 16:02:24
updated: 2021-10-01 16:02:24
tags:
	- LSH
	- MinHashing
categories: Algorithm
---



<!-- more -->

---

试想你有一些文本它们可能有所重复，你需要对他们进行去重处理，传统的做法是$O(N^2)$，即对所有的文本对进行相似度的计算，然后进行排序得到结果。

假设$N=10^6$，需要进行$\frac{N(N-1)}{2} = 5\times10^{11}$次计算，在果每秒计算$10^6$次，一天大概$10^5$秒，那么需要5天的时间，如果$N = 10^7$，则需要超过一年的时间。

显然$O(N^2)$的复杂度不可取，Locality-Sensitive-Hashing（LSH）利用hash把相似高的文本分到同一个桶中，这样过滤了大量不同的本文将计算降低到$O(N)$。

对于具体的任务，一般分为一下三个步骤：

1. Shingling，将文本转化为集合。
2. Min-Hashing，在保证相似度的前提下，将大的集合转化为短的签名。
3. Locality-Sensitive Hashing，关注可能来自相似文本的签名对。



接下来具体介绍这三个步骤。

![image-20211001172822844](https://img.sanzo.top/img/algorithm/image-20211001172822844.png)

## Shingling

一般特征矩阵需要自己获取，对于给定的文本，可以通过Shingling的方法构造特征集合。

例如文本为”abcabe“，可以构造为$k=2$的集合，$D = \{ab, bc, ca, be\}$，对于短的文本$k$一般取5，对于长的文本$k$取10。

我们可以对集合进行hash，将一个长的字符串表示为一个4字节的数字，$h(D) = \{1, 3, 2, 7\}$。

得到文本的集合之后，就可以通过计算集合的相似度，从而判断两个文本的相似性。

在计算相似度时，这里采用[Jaccard similarity](https://en.wikipedia.org/wiki/Jaccard_index)，$sim(D_1, D_2) = \frac{|D_1\cap D_2|}{|D_1\cup D_2|}$。

![image-20211001173617727](https://img.sanzo.top/img/algorithm/image-20211001173617727.png)

另外我们可以把集合表示为bit vector，这样求交集相当于AND运算，并集相当于OR运算。

![image-20211001173957028](https://img.sanzo.top/img/algorithm/image-20211001173957028.png)



## MinHashing

一般文本的集合都非常大，MinHashing相当于降维，同时近似的保持相似度的准确度。

MinHashing的具体做法时，对Shingles的集合进行随机打乱，bit vector为1的下标作为新的特征值。

![image-20211001174630022](https://img.sanzo.top/img/algorithm/image-20211001174630022.png)

MinHash相等的概率刚好等于Jaccard Similarity值，$Pr[h_\pi(D_1) = h_\pi(D_2)] = Jaccard(D_1, D_2)$。

证明如下：

对于两个document的集合来说，一共有三种情况：

- 对应维度全为1，设有$x$个。
- 对应维度只有一个1，设有y个。
- 对应维度全为0。

其中全为0的情况不影响MinHash的值，第一个非零行为第一类的概率为$\frac{x}{x + y}$。

另外从全排列考虑，第一行为第一类的情况有$x(x+y-1)!$，全排列为$(x+y)!$，$\frac{x(x+y-1)!}{(x+y)!}=\frac{x}{x+y}$即对特征进行全排列后，MinHash相等的次数即为Jaccard Similarity。

因此我们可以使用MinHash近似表示Jaccard Similarity，同时将长的vector压缩为短的签名。

![image-20211001175937408](https://img.sanzo.top/img/algorithm/image-20211001175937408.png)



假设有$K=100$个hash函数，对于每一列$C$和hash函数$k_i$，初始化$sig(C)[i]=\infty$，对于每一行的非零值，如果$k_i(j) < sig(C)[i]$，则更新$sig(C)[i] = k_i(j)$。





## LSH

通过MinHashing将特征矩阵转化为小的签名矩阵，接下来LSH将签名矩阵划分为$b$个band，每个band有$r$行，$len(sig) = b\times r$。

![image-20211001181506527](https://img.sanzo.top/img/algorithm/image-20211001181506527.png)

对于每个band，它们包含整体签名的一部分，将这部分签名通过hash映射到不同的桶中，如果两个签名相同它们就会映射到同一个桶中，经过b次映射，两个节点至少有一次被分到同一个桶中，我们就认为这两个节点的相似度更高。

假设两个签名的相似度为$t$，那么在同一个band中每一行都相同的概率为$t^r$，至少有一行不同的概率为$1-t^r$，所有的band都不相同的概率为$(1-t^r)^b$，至少有一个band相同的概率为$1-(1-t^r)^b$。

假设两个签名的相似度为$t$。

同一个band中每一行都相同的概率为$t^r$。

至少有一行不同的概率为$1-t^r$。

所有的band都不相同的概率为$(1-t^r)^b$。

至少有一个band相同的概率为$1-(1-t^r)^b$。

$b$和$r$是可调节的参数，下表是$b=20$，$r=5$的概率。

![image-20211001182918941](https://img.sanzo.top/img/algorithm/image-20211001182918941.png)



![image-20211001183025149](https://img.sanzo.top/img/algorithm/image-20211001183025149.png)

## 参考文献

[Finding Similar Items](http://www.mmds.org/mmds/v2.1/ch03-lsh.pdf)

[Mining of Massive Datasets](http://www.mmds.org/)

<!-- Q.E.D. -->

