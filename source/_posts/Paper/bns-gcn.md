---
title: >-
  BNS-GCN: 随机边界顶点采样加速分布式GCN训练
hidden: false
katex: true
sticky: 0
typora-copy-images-to: ../../img/
date: 2022-05-12 16:19:28
updated: 2022-05-12 16:19:28
tags:
  - sampling
  - distribute
  - gcn
categories:
  - Paper
---



<!-- more -->



MLSys'22 [paper](https://arxiv.org/pdf/2203.10983.pdf) [code](https://github.com/RICE-EIC/BNS-GCN) 

{%pdf https://arxiv.org/pdf/2203.10983.pdf %}



BNS-GCN认为分布式GCN训练的通信开销和边界点的数量成正比，在此基础上为了减少通信和内存占用，在每个epoch之前，他们对边界点进行采样（Boundary node sampling），通过大量的实验验证了BNS-GCN的性能，另外在对训练准确度提升上也给了理论的推导。



## Introduction

随着图规模的增加，GCN的训练对内存要求越来越高，节点的feature和邻接矩阵通常难以存放在单个机器内，为了解决这个问题，目前有三种方法：

1. 采样，通过采样可以有效的减少计算量和存储开销。例如GraphSage和VR-GCN通过邻居采样构建mini-batch；Cluster-gcn，Graphsaint基于子图采样作为训练样本。
2. 分布式训练，对图进行划分，有多个机器并行训练，通过通信进行必要的同步。例如NeuGraph、ROC、CAGNET、Dorylus、PipeGCN。分布式训练的主要问题是通信，限制了训练的高效性。
3. 异步训练，引入异步计算和通信，但是会staleness问题，例如Dorylus。



BNS这篇论文是基于分布式训练出发，研究分布式训练下通信和内存爆炸的根本原因，主要有3个贡献：

1. 分析并确定了分布式训练的主要挑战，同时定位到主要问题是过多的边界顶点数量（boundary nodes）而不是边界边（boundary edges）。
   - 巨大的通信量
   - 内存开销大
   - 内存开销不平衡
2. 提出BNS-GCN，在每个迭代随机采样边界顶点，该方法可以有效的减少通信和内存占用，同时拥有更好的准确度泛化能力，作者说他们是目前唯一一个在没有影响准确度和引入额外计算资源开销前提下减少通信量的工作。
3. 为BNS-GCN提高收敛性提供理论分析，通过大量实验BNS-GCN在相同准确度甚至更好的准确度下，在吞吐量上最高有16.2x的提升，内存占用最高减少58%。



## BackGround and Related Works

GCN的训练有两个主要的步骤：邻居聚合和顶点更新。

![image-20220512172500442](https://img.sanzo.top/img/paper//image-20220512172500442.png)

![image-20220512172509598](https://img.sanzo.top/img/paper//image-20220512172509598.png)

其中$\zeta^{(l)}$是对于邻居的聚合，这里使用mean聚合器，$\phi^{(l)}$是顶点的更新，BNS采用和Graph一样的更新操作:

![image-20220512173012908](https://img.sanzo.top/img/paper//image-20220512173012908.png)



### Sampling-Based GCN Training

基于采样的GCN训练一般包括：邻居采样，层采样、子图采样。

他们存在以下问题：

- 不正确的特征估计，尽管大多数采样提供对顶点特征的无偏估计，但是这些估计的方差损害了模型的精度，方差越小对准确度越有益。（Minimal variance sampling with provable guarantees for fast training of graph neural networks）
- 邻居爆炸，随着层数的增加，基于邻居采样的方法，采样的数量成指数增加（GraphSage），在限制邻居扩展的数量下对内存的要求仍很高。（Stochastic training of graph convolutional networks with variance reduction.）
- 采样开销，所有的采样算法都需要额外的时间来生成mini-batches，占到训练时间的25%+（Graphsaint）。





### Distributed Training for GCNs

GCN训练和传统的DNN训练的挑战不同：

1. DNN通常训练样本小，模型大。
2. 数据样本之间没有依赖。

分布式GCN训练的基本范式（1a），将整张图进行划分成小的子图，每个子图可以完整的放到GPU中，然后并行的进行训练，通信发生在子图间的边界点，用于交换顶点的feture。



![image-20220512175232658](https://img.sanzo.top/img/paper//image-20220512175232658.png)



ROC，NeuGraph、AliGraph遵循这样的范式，对图进行划分存储在CPU，然后交换子图的一部分到GPU进行训练。训练效率受限于CPU-GPU的swap开销。

CAGNET和$P^3$进一步对顶点feature和层进行切分，从而实现层内并行。这会造成严重的通信开销，尤其当feturea的维度很大的时候。

Dorylus使用大量的线程对每个细粒度的计算操作进行流水线处理来加速分布式训练，但通信仍是瓶颈。



## BNS-GCN Framework

Boundary Node Sampling，首先对图进行分区，使得边界点尽可能少，然后对边界点进行随机采样，进一步减少通信和内存开销。



![image-20220512202041065](https://img.sanzo.top/img/paper//image-20220512202041065.png)

图2是分布式GCN训练的过程，首先需要对图进行切分，将每个子图分配到不同的worker上，在做聚合邻居前，需要先通过通信获取远程依赖节点的feature，然后进行聚合操作和顶点更新操作得到下一层的顶点表示，这样就完成了一层的GCN计算，之后每一层的计算都是类似的过程，最后计算loss进行反向计算，反向计算逻辑和前向计算基本类似，最后通过AllReduce进行参数的更新。



### Challenges in Partition-Parallel Training

传统的训练方式有三个主要的挑战：

1. 大量的通信开销，Boundary Nodes的数量随着分区增多而增多，严重限制了扩展性。
2. 严重的内存占用，GPU需要同时存储Inner Nodes和Boundary Nodes。
3. 内存占用的不平衡，大量的Boundary Nodes导致部分GPU内存占用过高，同时也会导致其他GPU内存利用率不足。

作者认为这三个问题都是由于边界顶点造成的。



> Communication Cost Analysis

通信总量等于每个分区边界顶点的数量。

![image-20220512204517024](https://img.sanzo.top/img/paper//image-20220512204517024.png)



> Memory Cost Analysis

根据GraphSage（公式1，2）推出内存占用：

![image-20220512204554679](https://img.sanzo.top/img/paper//image-20220512204554679.png)



内存占用随着边界点线性增加，使用METIS对Reddit划分为10个分区后，每个分区的边界点和内部点的比例，在一些分区中比例高达5.5x，导致通信和内存开销过高。

![image-20220512205006629](https://img.sanzo.top/img/paper//image-20220512205006629.png)



> Memory Imbalance Analysis

![image-20220512205324706](https://img.sanzo.top/img/paper//image-20220512205324706.png)

由于边界点的分布不均衡，导致内存占有的不平衡，随着分区数量的增多，不平衡的现象越明显，图3是将ogbn-papers100M划分为192个分区，统计boundary-inner比例的分布，有一小部分的比例高达8，不仅会造成大量的内存占用，同时也会导致其他分区内存利用不足。



### BNS-GCN Technique

> Graph Partition

图分区的两个目标：

1. 最小化边界点的数量，因为边界点的数量直接影响通信量。
2. 分区的计算平衡，因为在每一层都需要同步通信，分区的计算不均衡，会阻塞其他分区的执行。

已有的工作，CAGNET和DistDGL只关注目标2，BNS-GCN同时考虑了目标1和2。

对于目标2来说，BNS-GCN近似的认为每个顶点的计算复杂度一样，对于GraphSage来说，计算复杂度主要由公式2决定，对于这种情况来说，图分区就是设置大小相等的分区。

然后针对目标1进行优化，BNS-GCN默认采用METIS进行图划分，目标优化是最小的通信开销，即最小数量的边界顶点。

METIS的复杂度是$O(E)$，而且只需要在预处理阶段执行一次。



> Boundary Node Sampling (BNS)

即使使用最佳的分区方法，边界点的问题仍然存在，表1。因此需要提出新的方法减少边界点的数量。

该方法需要实现3个目标：

1. 大幅减少边界点的数量
2. 最小的额外开销
3. 保证训练的准确度

BNS-GCN的核心思想是在每个epoch训练前，随机选择边界点的一个子集，存储和通信只发生在这个子集上，而不是原来整个边界点集。

BNS-GCN的具体算法步骤如下：

输入是每个分区上的子图信息以及对应feature和label。

首先根据边界点得到Inner Nodes，对于每个epoch，根据采样概率p对边界点进行采样得到训练的子图，然后通过broadcast的方式将采样到的节点信息通知到其他节点；节点收到来自不同分区的采样信息后，对Inner Nodes取交集进而确定向不同分区发送的feature；在具体训练过程中，首先通过通信获取远程节点的feature，然后在本地进行前向计算；反向计算逻辑类似，将所需的梯度发送到对应的分区进行反向计算；最后通过AllReduce进行参数的更新。



![image-20220512210137712](https://img.sanzo.top/img/paper//image-20220512210137712.png)



BNS-GCN的采样开销很低，大概占训练时间的0%-7%，基于通信的分布式训练都可以借鉴BNS-GCN的这个算法。



### Variance Analysis

feature的近似方差决定了梯度噪声的上限（Minimal variance sampling with provable guarantees for fast training of graph neural networks. SIGKDD）。

基于采样的方法，较低的近似方差拥有更快的收敛速度和更高的准确度（Sgd: General analysis and improved rates. PMLR 2019）。

表格2是BNS-GCN和不同采样算法的方差对比，VR-GCN无法直接比较，和其他的相比都要更小。

![image-20220513123942157](https://img.sanzo.top/img/paper//image-20220513123942157.png)





#### BNS-GCN vs Existing Sampling Methods

- 顶点采样，GraphSAGE和VR-GCN采用顶点采样，可能会对相同的节点采样多次，受限于GCN的层数和训练效率，BNS-GCN不会采样邻居节点，这显著减少采样方差估计和采样的开销。
- 层采样，BNS-GCN类似层采样，同一分区的节点共享上一层中相同的采样边界节点。和FastGCN、AS-GCN、LADIES相比，BNS-GCN拥有更密集的采样层可能导致更高的准确度。
- 子图采样，BNS-GCN可以看作是子图采样，因为它选择丢弃一些边界点，ClusterGCN和GraphSAINT也是子图采样，但是他们选择的顶点非常少，占总点数的1.3%-5.3%，因此会造成梯度估计的高方差。
- 边采样，在分布式训练GCN场景下应用边采样是不高效的，而且它并不会直接减少边界点的数量。



## Experiments



实验使用4个数据集：

BNS-GCN是在DGL上实现的，使用Gloo作为的通信后端。

对于Reddit、ogbn-products、Yelp在一台Xeon 6230R@2.10GHz（187GB）with 10 RTX-2080Ti（11GB）上跑，对应最小的分区为2，5，3。

对于ogbn-papers100M使用32台机器，每台拥有6块V100（16GB）with IBM Power9（605GB）。

为了可复现性和鲁棒性，实验中并没有去对超参数进行调节。

![image-20220513152000809](https://img.sanzo.top/img/paper//image-20220513152000809.png)





### Comparison with the SOTA Baselines

> Full-Graph Training Speedup

下图是和ROC、CAGNET，在分布式训练下GPU的吞吐量的对比，在p=0.01是吞吐量比ROC提高8.9x-16.2x，比CAGNET(c=2)提高9.2x-13.8x。即使是p=1时，BNS-GCN的吞吐量也比ROC高1.8x-3.7x，比CAGNET(c = 2)高1.0-5.5x。原因不仅是因为对边界点采样减少了通信的开销，对比ROC来说BNS-GCN没有CPU-GPU的swap开销，对比CAGNET来说BNS-GCN没有冗余的广播同步开销。

同样随着分区的增加，BNS-GCN（p < 1）的表现越好，thank to drropping boundary nodes。



![image-20220513152016856](https://img.sanzo.top/img/paper//image-20220513152016856.png)





> Full-Graph Accuracy

这个实验说明BNS-GCN可以保持甚至提升训练的准确度，分别和7种采样算法进行对比。

首先p=1时，和其他采样算法相比，BNS-GCN可以达到相当或者更高的准确度，这和ROC的结果一致。

当p=0.1/0.01时，BNS-GCN总能保持甚至提高整体的准确度。

当p=0时，和p>0对比在三个数据集上表现最差，这是由于每个分区丢弃了所有边界点，独立的进行计算。



![image-20220513152054808](https://img.sanzo.top/img/paper//image-20220513152054808.png)



> Improvement over Sampling-based Methods

表5是在ogbn-products数据集上和基于采样方法的训练性能的对比，可以看到当p=0.1/0.01时训练性能和准确度都要优于其他基于采样的方法。



![image-20220513152103955](https://img.sanzo.top/img/paper//image-20220513152103955.png)



![image-20220513164144507](https://img.sanzo.top/img/paper//image-20220513164144507.png)



### Performance Analysis

> Training Time Improvement Breakdown

这个实现是对BNS性能的分析，分别统计了计算、边界点通信，参数同步的时间。

可以看到边界点的通信dominate真个训练时间（p=1），在Reddit上最高占67%，在obgn-products最高占64%（p=1）。

当p<1时，边界点的通信时间明显减少，当p=0.01时和p=1对比，在Reddit上减少了74%-93%，在obgn-products减少了83%-91%。



![image-20220513164420787](https://img.sanzo.top/img/paper//image-20220513164420787.png)





除了在单机多卡环境下，同时在多机器下验证了BNS-GCN的性能。

p=0.01时缩短了整体99%的计算时间，同样也说明分布式场景下，通信是主要的瓶颈，这也是为什么BNS-GCN可取的原因。

![image-20220513152138546](https://img.sanzo.top/img/paper//image-20220513152138546.png)



> Memory Saving

这个实验是和p=1时对比内存占用减少的情况，在Reddit数据上，p=0.01时可以节省58%的内存占用，对于稀疏的ogbn-products来说同样可以减少27%的内存占用。

内存节省随着分区的增加效果越好，这是边界点随着分区增加而变多，这也进一步说明BNS-GCN在训练大规模图的可扩展性。



![image-20220513164429757](https://img.sanzo.top/img/paper//image-20220513164429757.png)



> Generalization Improvement

为了说明BNS-GCN的泛化能力，这个实验观测了不同分区下的测试准确度的收敛性。

这里选择ogbn-products数据集，是因为它的测试集的分布和训练集有很大的不同。

可以看到当全图训练p=0和独立训练p=1时模型会很快的过拟合，但是p=0.1/0.01时过拟合得到了缓解，而且提高了整体的准确度，这是因为BNS-GCN在训练过程中随机的修改了图结构。

相对来说p=0.1的准确度更好，p=0的收敛性和收敛的gap也是最大的，因为它完全删除了边界点。

![image-20220513152131535](https://img.sanzo.top/img/paper//image-20220513152131535.png)

图9是在另外两个数据集的表现，基本也符合总体的预期。

![image-20220513174402065](https://img.sanzo.top/img/paper//image-20220513174402065.png)









> Balanced Memory Usage

为了分析分区的内存平衡情况，这里将ogbn-paper100M数据集划分为192个分区。

对不不采样的情况p=1来说，存在严重的内存不均衡，straggler的内存占用比上限高20%，$\frac{3}{4}$的点的内存占用少于60%。

相反当p=0.1/0.01时内存占用更加均衡，所有分区的内存占用高于70%。



![image-20220513152233651](https://img.sanzo.top/img/paper//image-20220513152233651.png)





### Ablation Studies

> BNS-GCN with Random Partition

为了验证BNS-GCN的有效性是否依赖METIS划分器，这里做了个实验，将METIS划分替换为随机划分。

可以看到表7，在p=0.1时Random和METIS表现相当（-0.2～+0.27）。因此BNS-GCN和图的划分是正交的，适用于任何图划分方法。



![image-20220513152216539](https://img.sanzo.top/img/paper//image-20220513152216539.png)



作者进一步做实验，验证不同划分策略对BNS-GCN性能的影响，从表8可以看出，Random划分具有更高的吞吐量和更低的内存占用，因为随机划分会产生更多的边界点。

![image-20220513152223889](https://img.sanzo.top/img/paper//image-20220513152223889.png)



> The Special Case

对于特殊的例子p=0来说，一般实践中不推荐使用。

- 首先它在所有的数据集和分区方法中准确度最差（表4，7），特别在随机划分中，准确度从97.11%掉到了93.37%。
- 在不同的数据集和不同数量的分区上，收敛速度最慢。
- 严重的过拟合问题，图7。

因此推荐p取0.1/0.01，关于p的选择作者做了一个实验，发现p=0.1时在吞吐量、通信减少、内存减少、收敛速度、准确度、采样开销等表现最好。

![image-20220514162308250](https://img.sanzo.top/img/paper//image-20220514162308250.png)



> BNS-GCN vs Boundary Edge Sampling

Aligraph，Distdgl，Scalable and expressive graph neural networks via historical embeddings，认为通信的开销来自分区间的边，因此他们使用最小边切，通过对边进行采样例如DropEdge进一步减少通信，甚至只对边界边进行采样而不是对整张图。

本实验对BES和DropEdge进行对比，为了对比的公平性，保证drop相同数量的边。

在Reddit数据集上，DropEdge和BES的通信时BNS-GCN的10x，7x，总时间时BNS-GCN的2.0x和1.4x，这是因为在图中多个边界边可能连接到相同的边界点，即使drop掉一些边界边，但是剩余undropped的边仍然需要通信那些边界点，分布式GCN训练的通信仅与边界点的数量成正比（公式3）。



![image-20220513152244993](https://img.sanzo.top/img/paper//image-20220513152244993.png)





> BNS-GCN Benefit on GAT

为了验证BNS-GCN在不同模型的通用性，这里做了一个GAT模型的实验（2layer 10 partitions），可以看到BNS-GCN仍有58%～106%的加速。

![image-20220513152253329](https://img.sanzo.top/img/paper//image-20220513152253329.png)













<!-- Q.E.D. -->
