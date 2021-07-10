---
title: 'Grape: Parallelizing Sequential Graph Computations'
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-06-30 21:10:42
updated: 2021-06-30 21:10:42
tags:
categories: Paper
---

Grape是一个并行的图计算系统，可以将整个图算法作为整体并行的计算，和其他的系统不同，不需要重写图算法来适应系统，可以很方便的将算法以"plugged into"的方式执行，只要算法是正确的，Graph就可以在单调的条件下得到正确答案。

<!-- more -->

---

## Paper link

[Parallelizing Sequential Graph Computations](https://homepages.inf.ed.ac.uk/wenfei/papers/sigmod17-GRAPE.pdf)

{% pdf https://img.sanzo.top/pdf/paper/sigmod17-GRAPE.pdf %}



## Introduce

![image-20210703165424167](https://img.sanzo.top/img/paper/image-20210703165424167.png)

图1是Grape的编程接口，对于一个查询$Q$，用户需要自定义三个函数：PEval、IncEval和Assemble，在配置面板，用户可以选择图分区策略和worker的数量。



![image-20210703165504851](https://img.sanzo.top/img/paper/image-20210703165504851.png)



图2是Grape的工作流：

- 首先worker对本地数据$F_i$执行$PEval$，得到部分结果$Q(F_i)$。
- worker以消息的方式同步的交换信息，接受到消息$M_i$后做增量计算$Q(F_i\bigoplus M_i)$。
- 不断地重复步骤2直到worker不再有新的消息产生，此使Assemble pulls partial answers $Q(F_i\bigoplus M_i)$，聚集得到$Q(G)$。



Grape负责消息传递、负载均衡和容错等细节，用户不需要重新将整个算法转换为新的模型。



### Related work

关于图的并行计算模型有：

- PRAM，在共享内存上抽象的并行RAM访问。
- BSP，在superstep中模拟并行计算，包括本地计算、通信和同步屏障。
  - Pregel实现了以顶点为中心的BSP模型，每个超步节点并行的执行用户自定义的函数。
  - GraphLab修改了BSP，通过异步的方式传递消息。
  - Block-centric模型，将顶点为中心的编程扩展到blocks。
- MapReduce



比较流行的图处理系统有：

- GraphX，在分布式数据流框架中，通过spark的map操作将图计算重新定义为一系列的join和分组阶段。
- Grace，提供一个operator-level的迭代编程模型，通过异步来加强BSP。
- GPS，通过扩展APIs和分区策略实现Pregel。



以上系统都需要对图算法的重塑以适应系统的模型。



Grape采用BSP模型，和其他系统不同的是：

- Grape通过结合partial evaluation和incremental computation来实现算法的并行。
- 和Mapduce不同，通过graph fragmentation凸显数据并行，不需要在每次迭代计算后发送整个算法。
- 顶点为中心的Pregel是Grape的特列，可以看作Grape的每个fragment限制在单个顶点上，因为fragment，Grape相对Pregel减少了通信量和调度开销。

另外Grape可以使用**graph-level**的优化算法，这些在以顶点为中心的系统是无法实现的。

先前的系统都没有使用有界的增量计算来加速迭代计算，并且都不能保证并行计算的正确性。 



## Perliminaries

![image-20210703192952595](https://img.sanzo.top/img/paper/image-20210703192952595.png)

表2是一些图的符号定义。

### Partition strategy

给定一个数字m，分区策略$P$将图$G$划分成fragments $F=(F_1,...F_m)$，其中$F_i=(V_i, E_i, L_i)$是$G$的子图，$E=U_{i\in [1,m]}E_i,\space V=U_{i\in[1,m]}V_i$。

$F_i$分配到Worker$P_i$中：

- $F_i.I$是所有指向$F_i$的点集合。
- $F_i.O$是$F_i$指向的点集合。
- $F.O=U_{i\in [1,m]}F_i.O,\space F.I=U_{i\in[1,m]}F_i.I;\space F.O=F.I$。



$G_P(v)$可以得到$(i\rightarrow j)$，其中$v\in F_i.O\space v\in F_j.I \space with\space i \ne j$。



## Programming with Grape

### PEval: Partial Evaluation

#### Message preamble

声明状态变量$\overrightarrow{x}$和特定的顶点集合$C_i$，$C_i\overrightarrow{x}$即为$F_i$的更新集合。更具体的$C_i$由$d$和$S$指定，S是$F_i.I$或$F_I.O$，$C_i$是$S$中d-hops的节点和边的集合。

#### Message segment

PEval可以指定$aggregateMsg$用于解决来自多个worker的消息冲突，如果用户没有指定，Grape提供一个默认的处理方法。



#### Message grouping

调度器$P_0$收到worker$P_i$的消息后执行以下两步操作：

- Identifying $C_i$

  根据分区策略$G_P$确定$C_i$。

- Composing $M_i$

  首先根据分区策略确定$P_j$（vetex cut or edge cut）将所有发送到$P_j$的消息合并成单个消息$M_j$，并发送到$P_j$。

  





![image-20210703231814414](https://img.sanzo.top/img/paper/image-20210703231814414.png)



图3是算法SSSP的PEval例子。



### IncEval: Incremental Evaluation

![image-20210704125540831](https://img.sanzo.top/img/paper/image-20210704125540831.png)







## Implementation of Grape



![image-20210704130106240](https://img.sanzo.top/img/paper/image-20210704130106240.png)



图5是Grape的架构图：

1. user interface
2. parallel query engine
3. Underlying the query engine are:
   - MPI Controller
   - Index Manager
   - Partition Manager
   - Load Balancer
4. storage layer mannages graph data in DFS



### Graph partition

user may pick：

1. METIS，a fast heuristic algorithm for sparse graphs.
2. vetex cut and edge cut partitions for graphs with small vertex cut-set and edge cut-set.
3. 1-D and 2-D partitions, which disribute vertex and adjacent matrix to the workers.
4. a fast hight degree nodes to reduce cross edges



### Graph-level optimization

#### Indexing

1. 2-hop index for reachability queries.
2. neighborhood-index for candidate filtering in graph pattern matching.



#### Compression

Grape在fragment level采用query preserving compression。

对于给定的查询Q，每个worker通过压缩算法离线的计算一个更小的$F_i^c$。



#### Dynamic grouping

Grape通过添加一个虚拟节点动态的分组一系列点，并分批从虚拟节点发送消息。



#### Load balancing

Grape将计算任务分组到work units，并检查每个virtual worker $P_i$的开销，包括fragment size$|F_i|$，border nodes in $F_i$，查询Q的计算复杂度，load balancer最小化work unit的计算开销和通信开销。



### Fault tolerance

Grape采用arbitrator mechanism实现对worker和coordinator的恢复，令其中一个worker为arbitrator，一个为standby coordinator，它们不断地向worker和coordinator发送心跳包，如果对方没有恢复，则使用备用的worker替换失败的worker和coordinator。





### Consistency

Grape允许用户指定aggregateMsg来处理消息冲突，如果用户没有指定，Grape将执行默认的处理函数。

另外Grape实现了一个轻量级的transaction controller，处理queries、insertions and deletions of nodes and edges.



## Experimental

### Setting

Dataset：

- liveJorunal, 4.8 million entities and 68milion relationships, with 100 labels and 18293 connect components.
- DBpedia, 28 million entities of 200 types and 33.4 million edges of 160 types.
- traffic, 23 million nodes and 58 million edges.
- movieLens, 10 million movie ratings, 71567 users and 10681 movies. (for collaborative filtering)

Queries：

- 对每个图随机采样10个点，对每个点生成SSSP query。
- 为Sim和Sublso生成20个pattern queries。

Algorithm：

默认的分区策略为METIS。

Environment：

Aliyun ECS n2.large，Intel Xeon processor 2.5GHz，16G memory。



### Result

![image-20210704220128070](https://img.sanzo.top/img/paper/image-20210704220128070.png)

(a) 从上图可以看出，Grape通过简单的并行顺序算法而不做进一步的优化，就可以和最先进的系统相媲美。

另外图(b)和图(c)可以看出，Grape在从liveJourmal到DBpedia上性能提升要打羽GraphLab和Graph，这是因为vertex-centric算法需要更多的supersteps才能达到收敛。



(b) 随着n的增大(processors)每个系统的运行时间都显著下降，其中与Giraph和GraphLab相比Grape的加速比最大，n从4到24Grape平均要快4倍。





![image-20210704220147557](https://img.sanzo.top/img/paper/image-20210704220147557.png)

(c) Grape的通信量远小于其他系统。





。。。







<!-- Q.E.D. -->