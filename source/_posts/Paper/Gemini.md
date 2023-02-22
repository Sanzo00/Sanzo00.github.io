---
title: Gemini代码阅读
hidden: false
katex: true
sticky: 0
typora-copy-images-to: ../../img
date: 2023-02-22 20:25:55
updated: 2023-02-22 20:25:55
tags:
	- gemini
	- graph processing
	- code
categories: Paper
---

<!-- more -->

---

[Paper](https://www.usenix.org/system/files/conference/osdi16/osdi16-zhu.pdf) [Slides](https://www.usenix.org/sites/default/files/conference/protected-files/osdi16_slides_zhu.pdf) [Code](https://github.com/thu-pacman/GeminiGraph)

Gemini是发表在OSDI16的一篇关于图计算系统的文章。

之前写过一个Gemini论文笔记的blog：[Gemini论文笔记](https://blog.csdn.net/henuyh/article/details/114197800)，最近又重新看了下代码实现，在这里简单记录下Gemini的图结构和通信的设计与实现。





## 图结构

**stage 1** 

- Partition Graph along out_degrees fllow by (edges + nodes * alpha), alpha = alpha = 12 * (partitions + 1);
- eache partitions vertices num is dive by PAGESIZE (1024)
- read edge, compute outdegree, determine partition_offset

![image-20230222203418793](../../img/paper/gemini/image-20230222203418793.png)



**Stage 2： Numa-Aware sub-chunking**

- outgoing_structure: each socket hold the edges tha dst belongs to and these edges partition by src.
- incoming_structure: each socket hold the edges tha src belongs to and these edges partition by dst.
- each worker read partial edge file and send edge to corresponding worker according to dst (outgoing) and src (incoming).

![image-20230222203455887](../../img/paper/gemini/image-20230222203455887.png)





## 通信

Stage1: Eacher partition send socket's msg to other partitions

Stage2: each socket in the partition will handle all the message recv from other partition

![image-20230222203812970](../../img/paper/gemini/image-20230222203812970.png)





## 代码

下面以SSSP算法在sparse模式下为例子，介绍下图结构和通信的实现细节。

### 图结构

确定每个分区的节点：

![image-20230222211124934](../../img/paper/gemini/image-20230222211124934.png)



每个分区再进行一次numa-awre的划分，即确定每个socket负责的节点范围：

![image-20230222211222604](../../img/paper/gemini/image-20230222211222604.png)



接下来是决定outgoing structure，gemini的图结构存储是站在mirror的角度考虑的。

首先是标记每个socket的入邻居（有哪些mirror指向我这个socket里面的节点）。

![image-20230222212002231](../../img/paper/gemini/image-20230222212002231.png)



outgoing对应CSR结构，首先是获取offset数据（src指向本地点的偏移量）

![image-20230222212215425](../../img/paper/gemini/image-20230222212215425.png)



有了offset之后，然后获取对应的dst点。

![image-20230222212326121](../../img/paper/gemini/image-20230222212326121.png)



incomming的结构类似，这里就不再说明了。





tune_chunks函数的作用是对每个socket存储的图结构，再进行一次thread粒度的划分。
![image-20230222212832368](../../img/paper/gemini/image-20230222212832368.png)



![image-20230222212908947](../../img/paper/gemini/image-20230222212908947.png)



### 通信



每个worker创建发送和接收的buffer：

![image-20230222204048137](../../img/paper/gemini/image-20230222204048137.png)



每个分区将本地活跃节点，通过sparse_signal产生一个消息，这个消息先是会到线程的buffer里面，然后再到socket对应的buffer里面。

![image-20230222204325107](../../img/paper/gemini/image-20230222204325107.png)



![image-20230222204744262](../../img/paper/gemini/image-20230222204744262.png)



通过MPI完成消息的发送和接收。

![image-20230222204617892](../../img/paper/gemini/image-20230222204617892.png)





在GeminiPush模式下，Master首先将消息同步到Mirror端，然后mirror更新自己本地的出邻居（outgoing）。

![image-20230222205110269](../../img/paper/gemini/image-20230222205110269.png)



在sparse-signal函数中，对于活跃点的产生消息这一步骤，是由多个线程并行完成的。

![image-20230222205246481](../../img/paper/gemini/image-20230222205246481.png)



接收端处理消息时，对于发来的socket消息，本地的每个socket都会对这个消息进行处理，这样就确保图结构的完整性。

![image-20230222205641659](../../img/paper/gemini/image-20230222205641659.png)



这个地方可能有点绕，举个例子：

![image-20230222210953416](../../img/paper/gemini/image-20230222210953416.png)







<!-- Q.E.D. -->