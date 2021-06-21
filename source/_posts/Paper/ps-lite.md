---
title: '论文笔记: ps-lite'
katex: true
date: 2021-06-18 13:58:33
updated: 2021-06-18 13:58:33
tags: ps-lite
categories: Paper
typora-copy-images-to: ..\..\img\paper
---



作者提出了第三代参数服务器的开源实现，采用异步的通信模型，灵活的一致性模型，以平衡系统效率和算法收敛的速度。另外提供了弹性的扩展性和容错，在处理数10亿级别的数据仍有很高的效率。

<!-- more -->

---

## 论文地址

[Scaling Distributed Machine Learning with the Parameter Server](http://www.cs.cmu.edu/~muli/file/parameter_server_osdi14.pdf)

{% pdf https://img.sanzo.top/pdf/paper/parameter_server_osdi14.pdf %}





## 介绍

分布式优化和推理正在成为解决大规模机器学习问题的先决条件，随着数据的增加产生的复杂模型，单机无法迅速的解决这些问题，而实现一个高效的分布式算法并非易事，密集的计算和通信数据量都需要精心的设计，现实生活中的训练数据可以达到1TB~1PB，各个worker需要频繁的访问这些模型参数，这就带来了三个挑战：

- 访问参数需要大量的带宽。

- 大多机器学习算法是线性的，同步和机器延迟严重形象了整体的性能。

- 在云环境下集群的训练，容错是至关重要的。

  ![image-20210618170716832](https://img.sanzo.top/img/paper/image-20210618170716832.png)

### 贡献

作者提出了参数服务器的第三代开源实现，重点关注于分布式推理的系统层面，为开发者带来了两种优势：

- 通过分解机器学习系统中常用的组件，使得特殊用途的代码保持简洁。
- 作为系统级别优化的共享平台，提供鲁棒性、通用性、高性能的实现，可以处理从sparse logistic regression到topic model和disributed sketching等各种类型的算法。

作者提出的参数服务器由5种关键特性：

- 高效的通信，采用异步的方式进行通信，减少了网络流量和开销。
- 灵活的一致性模型，宽松的一致性隐藏了同步的开销和延迟。
- 弹性的可伸缩性，可以方便的添加节点，而不需要重启正在运行的框架。
- 容错和持久性，从非灾难性机器故障可以在1s内恢复而不用中断计算，向量时钟保证分区和故障后定义良好的行为。
- 容易使用，全局共享参数表示为向量和矩阵的形式，方便机器学习应用的开发。

### 工程挑战

构建高性能的参数服务器有两个关键的挑战：

- 通信

  参数抽象为键值对的形式开销比较大，因为value通常很小(float、int)，很多学习算法表示为结构化的数学对象，例如向量和矩阵，在每次迭代，通常只有一部分需要更新，这为参数服务器在更新的通信、处理提供自动批处理的机会。

- 容错

  参数的实时复制支持热故障转移，故障切换和自动修复通过将机器的删除和添加视为故障和修复，从而支持动态的扩展。



![image-20210619100256182](https://img.sanzo.top/img/paper/image-20210619100256182.png)

上图是多个系统执行监督学习和无监督学习的实验规模总览，其中蓝圈表示sparse logistic regression，红框表示latent variable graphical models，灰色表示deep networks，通过对比可以看出在规模处理器下参数服务器可以覆盖更大数量级的数据。



![image-20210619101219789](https://img.sanzo.top/img/paper/image-20210619101219789.png)

表2概述了几种机器学习系统的主要特征，参数服务器在一致性上提供最大程度的灵活性，同时唯一提供连续容错性，采用的数据类型可以方便的用于数据分析。



### 相关工作

第一代参数服务器是由A. J. Smola and S. Narayanamurthy提出的 [An architecture for parallel topic models. In Very Large Databases](https://alex.smola.org/papers/2010/SmoNar10.pdf)将分布式缓存(key value)用于同步机制，YahooLDA在此基础上通过实现一个用户可定义的更新原语（set、get、update）的专用服务器和一个更有原则的负载分配算法改进了这个设计。

第二代专用的参数服务器可以在Distbelief（[Large scale distributed deep networks. In Neural Information Processing Systems](https://papers.nips.cc/paper/4687-large-scale-distributed-deep-networks)）中找到，其中的同步机制为[Parameter server for distributed machine learning](https://www.cs.cmu.edu/~muli/file/ps.pdf)。

基于Hadoop的Mahout和基于Spark的MLI都采用了MapReduce框架，MLI和Spark的关键点是保存迭代间的状态。

GraphLab使用图抽象的异步通信机制，缺少像基于map/reduce的可扩展性，同时依赖于粗粒度的快照恢复，两者阻碍了可伸缩性。

从某种角度来说，参数服务器的核心目标是捕获GraphLab的异步特性，同时减少它的结构限制。

Piccolo在机器之间共享和聚集状态，worker在本地聚集，然后同步到server端，但是缺少机器学习的特定优化：消息压缩、复制和通过依赖图的变量一致性模型。

## 机器学习

机器学习的目标通常是优化一个最小化模型，不断地根据梯度优化模型的参数，从而提高预测的准确度。

![image-20210620111002084](https://img.sanzo.top/img/paper/image-20210620111002084.png)

公式1是一个常见目标函数的求解，$l$表示损失函数，$\Omega$为参数的正则化。



![image-20210620111211430](https://img.sanzo.top/img/paper/image-20210620111211430.png)

图2描述了参数服务器的执行流程，每个worker只需要加载部分数据，每次从server获取新的参数，然后在本地进行计算，最后把梯度传到server，这样就完成了一次迭代。

算法的执行流程如下：

![image-20210620111340168](https://img.sanzo.top/img/paper/image-20210620111340168.png)





## 系统架构

![image-20210620100554972](https://img.sanzo.top/img/paper/image-20210620100554972.png)

server group中有多个server节点，每个server节点维持着全局共享参数的一部分，server节点相互通信以复制或迁移参数，来提高系统的可靠性和伸缩性。

server manager node维护server节点的元数据，例如节点的活跃和参数分区的分配。

每一个worker group跑一个应用，每个worker保存一部分训练数据在本地进行计算，worker只与server节点进行通信，用于更新和获取参数信息。

每个worker group都由一个task scheduler，负责给worker分配任务并监督他们的状态，如果添加或删除节点，它会重新调度未完成的任务。

参数服务器支持独立的参数命令空间，允许worker group隔离它们彼此的参数。

多个worker group也可以共享相同的参数名称空间，因为可能同时需要多个worker group处理相同的深度学习任务，以提高并行度。



### (key,value)向量

机器学习算法通常处理线性代数对象，参数服务器将模型共享的参数抽象为(key,value)形式的向量，同时使key有序排列。这减少了优化算法的编程工作，同时可以使用各种高效的线性代数算法库。



### Range Push and Pull

参数服务器提供Range的push和pull，方便程序员和提高计算和网络带宽的效率。

> 这个例子不太懂？

![image-20210620220305566](https://img.sanzo.top/img/paper/image-20210620220305566.png)



### User-Define Functions on the Server

server节点除了聚集来自worker的梯度，还可以执行用户自定义的函数，因为server端保存着最新的参数，可以执行很多其他的操作。

```bash
At the same time a more complicated proximal operator is solved by the servers to update the model in Algorithm 3. In the context of sketching (Sec. 5.3), almost all operations occur on the server side
```



### Asynchronous Tasks and Dependency

任务的异步是指，调用者在发出任务后立即执行进一步的计算。

调用者在收到被调用者的回复后，将任务标记为完成状态，回复可以是用于自定义函数的返回值、pull指令的（key，value），或是空的应答数据。

被调用者只有在任务返回而且所有的子任务都完成，才会将任务标记为完成状态。



默认情况下，被调用者并行的执行任务，调用者希望串行的执行任务，因为一些任务依赖另一个任务。

![image-20210620225514703](https://img.sanzo.top/img/paper/image-20210620225514703.png)

图5描述了WorkIterate三个迭代的例子，其中10和11相互独立，12依赖于11，11在10完成梯度计算后立即执行，而12需要等待11pull完成才能开始执行。



### Flexible Consistency

任务的独立性使得可以并行的执行多个任务，从而提高了系统的效率，但是这回造成数据的不一致性，对于图5来说，迭代11在10未更新前就开始计算梯度，即$g_r^{11} = g_r^{10}$，这种非一致性潜在的减慢了模型的收敛。

但是对于一些其他的算法可能对非一致性不太敏感，例如range的pull和push，不一致性只会影响range对应的参数。

系统性能和算法的收敛素的的权衡依赖于多个变量：算法对一致性的敏感程度、训练数据的特征相关性、硬件组件的差异，和其他机器学习强制用户采用特定的依赖性不同，参数服务器提供给算法设计者一个灵活的一致性模型。

![image-20210620231544678](https://img.sanzo.top/img/paper/image-20210620231544678.png)

图6描述了3中不同的依赖模型。

- Sequential，所有的任务按照顺序执行，通常也称为Bulk Synchronous Processiong。
- Eventual，所有的任务同时进行，只有在底层算法在延迟方面是健壮的才建议这样做。
- Bounded Delay，设置最大的延迟时间$\tau$，当前$\tau$个任务没有完成时，就会阻塞当前任务。$\tau = 0$为sequential一致性模型，$\tau = \infty$为Eventual一致性模型。

依赖图可以是动态的，调度器根据当前任务执行的情况，动态的调整$\tau$的大小。

> 这个地方不太懂?

```bash
the caller traverses the DAG. If the graph is static, the caller can send all tasks with the DAG to the callee to reduce synchronization cost.
```



### User-defined Filters

用户自定义过滤器可以对任务的数据一致性进行细粒度的控制。

例如一个significantly modified filter只push自上次同步以来更新超过阈值的参数。

第5.1节的KKT，只push’可能影响server权重的梯度。







## 实现

### Vector Clock

使用向量时钟可以方便的记录参数聚集的状态，避免重复发送和接收数据。

最普通的实现方式是每个节点都维护所有的 参数，空间复杂度为$O(nm)$，$n$是节点个数，$m$是参数个数。

当基于range的参数通信时，这些参数具有相同的时间戳，因此可以间range的节点压缩为一个时间，此时空间复杂度为$O(nk)$，$n$为节点个数，$k$为算法中range的出现的种类数，空间远小于$O(nm)$。

![image-20210621101516237](https://img.sanzo.top/img/paper/image-20210621101516237.png)

算法2是为节点$i$的range分配时间，每个集合最多划分为三个区间，其中与range相交的区域分配时间$t$。



### Messages

消息通常包含（key,value）列表和一个vector clock：$[vc(R),(k_1,v_1),\dots,(k_p,v_p)\space k_j \in R\space and \space j \in {1,\dots p}]$。

消息可能只携带部分key值，对于其他key他们value没有发生改变。

key一般是机器学习的训练数据，它通常不会改变，因此接收方可以缓存key值，发送方只需要发送list的hash而不是整个list。

value在sparse logistic regression中存在很多的零值，而且在用户自定义的过滤器也会出现大量的零值，因此为了减少通信量只发送非零值。

使用[Snappy compression library](http://google.github.io/snappy/)压缩消息（去除零值），同时采用key缓存。



### Consistent Hashing

![image-20210621114249140](https://img.sanzo.top/img/paper/image-20210621114249140.png)

参数服务器使用hash表的分区方式对key进行分区，每个server node负责一个范围的key。





### Replication and Consistency

 

![image-20210621114259280](https://img.sanzo.top/img/paper/image-20210621114259280.png)

每个server节点保存逆时针方向的k个server的key信息，图8左边是k=2的例子，$W_1$pull(x) to $S_1$，$S_1$执行用户自定义函数$f$，然后将结果备份到$S_2$。

图8右侧是多个Worker同时pull的例子，传统的方法是对每个pull请求都做一次计算然后备份，但是这增加了网络的带宽，参数服务器允许在Server端进行聚集计算，然后再 将结果备份到其他Server，如果有$n$个Worker需要备份$k$次，总带宽为$\frac{k}{n}$。

虽然聚集会增加响应的延迟，但是可以通过宽松的一致性来隐藏延迟。

### Server Mangement

为了实现容错和动态的扩展，需要动态的添加和删除节点，为了方便参数服务器采用虚拟节点进行管理，当有新的server加入，会执行以下步骤：

- server manager为新的节点分配key range，可能会造成其他key range的分隔或者从终止节点中删除。

- 节点获取key range数据以及备份k个邻居节点的数据。

  从某几个节点$S$获取范围$R$的数据需要经过两个阶段：

  1. $S$预先拷贝范围内的（key,value）以及vector clock，如果新节点启动失败，$S$不做任何改变。
  2. $S$不再接收范围$R$的任何消息，删除消息不再回复，同时向新节点发送在预拷贝阶段发生在$R$上的改变。

- server manager广播节点的改变，接收者可能会减少当前的key range，然后将未完成的任务分配给新节点。

  收到消息的节点$N$，首先检查自己是否维护着$R$，如果是将删除$R$的所有(key, value)和vector clock，然后遍历所有已经发送且还没有接受到回复的消息，如果涉及到范围$R$，则对消息进行划分并重新发送。

由于延迟、失败、丢包，发送方可能会发送两次消息，接收方更具vector clock可以拒绝消息，而不会影响正确性。



节点的删除和添加相同，server manager通过心跳信号检测节点的状态。

### Worker Management

Worker节点的添加过程如下：

- task scheduler为$W$分配数据。
- 节点从网络文件系统或已有的Worker中加载训练数据，然后从server pull 参数。
- task sheduler广播改变，可能会造成已有worker释放部分训练数据。

当Worker离开，task scheduler开始进行替换，允许算法设计者选择控制恢复的原因是：

- 如果训练数据很大时，恢复worker node要比恢复server node更加昂贵。
- 损失一部分的训练数据，可能只会对模型造成一点点的影响，因此算法设计者可以选择不恢复Worker，甚至停止某些进展慢的Worker是可取的。  



## 评测

### Sparse Logistic Regression

![image-20210621174855698](https://img.sanzo.top/img/paper/image-20210621174855698.png)

 算法采用分布式回归算法，与其他算法的不同：

- 每次迭代更新一个参数块
- worker计算块上的梯度和二阶导数对角线部分
- 参数服务器的server端需要进行更复杂的计算，通过求解基于聚合梯度的proximal operator来更新模型。
- 使用有界的更新模型，并使用KKT滤波器，抑制部分梯度的更新。



作者和两个专用的系统A和B进行对比：

![image-20210621184256210](https://img.sanzo.top/img/paper/image-20210621184256210.png)

通过对比可以发现系统A和B都需要10K多的代码量，而参数服务器只需要300行代码，由此可见参数服务器成功的将系统的复杂性，从算法实现转移到可重用的通用组件上。



图9是三个系统达到相同的objective value的表现，用时越少系统越优秀。

![image-20210621184634595](https://img.sanzo.top/img/paper/image-20210621184634595.png)

系统B要优于系统A，因为系统B使用了更好的优化算法。

参数服务器优于系统B，因为它减少了网络带宽以及使用了宽松的一致性模型。



图10展示了采用宽松的一致性模型，提高了节点的利用率：

![image-20210621184646135](https://img.sanzo.top/img/paper/image-20210621184646135.png)



从图中可以看出，系统A的worker闲置比率为32%，系统B的闲置比率为53%，参数服务器的限制比率为2%。

参数服务器比系统B对CPU利用率更高有两个原因：

- 系统B通过预处理优化了梯度计算
- 参数服务器的异步计算减缓了收敛速度，因此需要更多的迭代计算，优于降低了通信成本，因此时间总时间减半。



图11是评估每个系统组件对网络的减少占比，左图是server右图是worker：

![image-20210621185952312](https://img.sanzo.top/img/paper/image-20210621185952312.png)

从图中可以看出：

- 缓存key，server和worker可以减少一半的通信量。
- 使用KKT filter时，数据压缩在server端减少20x，worker端减少6x，原因如下：
  - 因为正则化的模型，从server端pull下的的参数大部分为0。
  - KKT filter使得发送到server的梯度大部分为0，从图12可以看出KKT可以过滤超过93%的keys。



![image-20210621190019933](https://img.sanzo.top/img/paper/image-20210621190019933.png)



图13是分析有界一致性的表现，worker在不同的$\tau$下达到相同的收敛状态的计算和等待时间占比：

![image-20210621190033176](https://img.sanzo.top/img/paper/image-20210621190033176.png)

当$\tau = 0$时有50%的worker时空闲的，当$\tau = 16$时空闲的worker占比降低至1.7%，但是计算的时间随着$\tau$线性的增长，这是数据的不一致减缓了收敛速度，结论是$\tau = 8$是最好的平衡。



### Latent Dirichlet Allocation

作者收集了50亿个用户的搜索日志数据，并对集中的500万个最频繁点击的网址进行评估。

算法采用了：Stochastic Variational Methods，Collapsed Gibbs sampling，distributed gradient descent。

![image-20210621200736686](https://img.sanzo.top/img/paper/image-20210621200736686.png)

从图14的右图可以看出机器数量从1000增加到6000，收敛速度提高了4x。

同时左图体现了系统的worker性能表现不一，因此能够应对worker不同性能的系统是非常关键的。

评估的结果如下：

![image-20210621201911068](https://img.sanzo.top/img/paper/image-20210621201911068.png)



### Sketches

引用Sketches用来评估系统的一般性，因为Sketches和传统的机器学习不同，它们通常需要观察来自流数据的大量写事件。

作者评估了在一个approximate structure中插入一个streaming log of pageviews的时间。

数据使用Wikipedia的page view的统计数据作为基准，从12/2007到1/2014，一共包含3000亿个entries，1亿个key。

实验环境是在15台机器上用90个虚拟服务器节点运行参数服务器，每个机器64cores，40Gb的带宽。

![image-20210621202903548](https://img.sanzo.top/img/paper/image-20210621202903548.png)

算法4是一个简单的CountMin Sketch算法，

![image-20210621202911914](https://img.sanzo.top/img/paper/image-20210621202911914.png)

实验得到系统插入的速率很高，这是因为：

- 批量通信减少了通信开销
- 消息压缩平均减少(key,value)50个bit。

另外系统可以在1s内恢复失败的节点。



<!-- Q.E.D. -->

