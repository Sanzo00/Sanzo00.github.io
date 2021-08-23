---
title: 'Galois: A Lightweight Infrastructure for Graph Analytics'
katex: true
typora-copy-images-to: ..\..\img\
date: 2021-08-11 09:55:51
updated: 2021-08-11 09:55:51
tags:
- galois
- DSL
- graph analytics
categories: Paper
hide: true
---



<!-- more -->

---

## Paper link

[A Lightweight Infrastructure for Graph Analytics](https://dl.acm.org/doi/pdf/10.1145/2517349.2522739)

{%pdf https://img.sanzo.top/pdf/paper/galois-A_Lightweight_Infrastructure_for_Graph_Analytics.pdf %}



## Contribution

- Galois provide for a rich programming model with **coordinated** and **autonomous** scheduling.

- topology-aware work-stealing scheduler.
- priority scheduler.
- a library of scalable data structures.



## Programming Model

amorphous data parallelism（ADP）is a data-centric programming model for expression parallelism in regular and irregular algorithms.

![image-20210811101315304](https://img.sanzo.top/img/paper/image-20210811101315304.png)

**Active nodes** in the graph where computation must be performed, they are shown as filled dots in Figure 1.

**neighborhood** is a set of graph elements read and write by an active node, thea are shown as a "cloud" surrounding that node. In general, neighborhoods are distinct from the set of immediate neighbors of the active node, and neighborhoods of different active node may **overlap**.



The key design choices when writing parallel graph analytics programs can be summarized as follows:

>  **what does the operator do?**

 In SSSP graph problem, there are two general ways that we call **push style** or **pull style**.

A push style operator reads the label of the active node and writes to the lables of its neighbors. information flows from the activate node to is neighbors.

A pull style opeartor writes to the label of the activate node and reads the labels of its neighbors. information flows to the active node from its neighbors.





> **where in the graph is it applied?**

Implementations can be **topology-driven** or **data-driven**.

An examples of topology-driven is Bellman-Ford SSSP algorithm, this algorithm perform $|V|$ supersteps, topology-driven computations are easy to parallelize by partitioning the node of the graph between processing elements.



In a data-driven computation, node become active in an **unpredictable**, active nodes are maintained in a **worklist**. **Data-deiven implementations can more work-efficient than topology-driven** since work is performed only where it is needed in the graph. But load balancing is more challenging.



> **when is the corresponding activity executed?**

When thera are more active nodes than threads, the implementation must decide which active nodes are **prioritized** for execution and when the **side-effects** of the resulting activities become visible to other activities.



In **autonomous scheduling**, activities are executed with **transactional semantics**, their execution are **atomic** and **isolated**. Threads retrieve active nodes from the worklist, synchronizing with other threads only as needed to ensure transactional semantics. This fine-grain synchronization can be implemented using l**ogical locks or lock-free** operations on graph elements.



Coordinated scheduling, restricts the scheduing of activities to **round of execution** as in the **Bulk-Synchronous Parallel** (BSP) model.



## Galois System

![image-20210811115326611](https://img.sanzo.top/img/paper/image-20210811115326611.png)

### Topology-aware bags of tasks

Galois scheduler uses a **concurrent bag** to hold the set of pending tasks (active nodes), it allow concurrent insertion and retrieval of unordered tasks and is implmented in a distributed, machine-topology-aware way as follows.

- Each core has a data structure called a **chunk** that can contain 8-64 tasks. (manipulated as a stack LIFO or queue FIFO).
- Each package has a list of chunks. This list also manipulated in LIFO order.
- When the chunk becomes empty, the **core probes its package-level** list to obtain a chunk. If the package-level list is also empty, the **core probes the list of other package** to find work. **only one hungry core hunts for work in other packages on behalf of all hungry** cores in a package (to reduce traffic on the inter-package connection network).



### Priority Scheduling

![image-20210811141533008](https://img.sanzo.top/img/paper/image-20210811141533008.png)

Priority scheduling is used extensively in OS, but os tasks are relatively coarse-grained may execute in tens or hundreds of milliseconds, where tasks in **graph analytics take only microseconds to execute**, as shown in Figure 2. Therefore the **overheads of priority scheduling in the OS context are masked by the execution time of task**, so **solutions from the operating systems area cannot be used here**.



Galois use obim schuduler, the **obim scheduler uses a sequence of bags**.

Each bag associated with one priority level. Task in the same bag have **identical priorityes** and can be **executed in any order**. 

**Earlier bags in the sequence are scheduled preferentially over those in later bags.**

Thread can **creates a task with some priority**, if corresponding bag is not there in the global map, thread **allocates a new bag**, updates the global map, and inserts the task into the bag.

**Global map is central data structure**, to prevent it from becoming a bottleneck and to reduce coherence traffic, each thread maintains a **software-controlled lazy cache** of the global map, as shown in Figure 4b.



#### implementation of global/local maps

Thread-local map is implemented by a **sorted**, dynamically resizable array of pairs. Use **binary search** to looking up a priority in the local map.

Threads also maintain a **version number** representing the last version of the global map they synchronized with.

> Updating the map

When a thread **can't find a bag** for a particular priority using only its local map, it will **replays the global log** from the point of the thread's last synchronized version to the end of the current global log. This will **inserts all newly created mapping into the thread's local map**. If the right mapping is still not found, the thread will acquire a write lock, **replay the log again**, and **append a new mapping to the global log and its local map**.



> Pushing a task

Thread use found or created bag for the push operation, as above.



> Retrieving a task

Thread may create one or more **new tasks with earlier priority than itself** because priorities are arbitrary application-specific functions, If so, the **thread executes the task with the earliest priority** and **adds all the other tasks to the local map**.

Threads search for tasks with a different priority only when the bag in which they are working becomes empty, the threads then scan the global map looking for important work, this procedure is called the **back-scan**.

scan over the entire global map can be expensive, **an approximate consensus  heuristic** is used to locally estimate the earliest priority work available and to prevent redundant back-scans, which we call **back-scan prevention**. 

Each thread **publishes the priority** it is working at by **writing it to shared memory**. When a thread needs to scan for work, it looks at this value and **uses the earliest priority to start the scan** for work.

One **leader thread** per package will scan the other package leaders. This restriction incur only a small amount of local communication.



#### Evaluation of design choices

![image-20210811202012098](https://img.sanzo.top/img/paper/image-20210811202012098.png)



![image-20210811202025706](https://img.sanzo.top/img/paper/image-20210811202025706.png)

Figure 5a shows the speedup of SSSP relative to the best overall single-threaded execution time. We can see the **back-scan prevention is critical** for performance. without this optimization, speedup is never more than 2.5.

without back-scan prevention, a distributed bag is less efficient than a centralized one on this input. This is because it is more efficient to check that a a single centralized bag is empty than it is to perform this check on a distributed bag.



### Scalable library and runtime

#### Memory allocation

Existing solutions do not scale to large-scale multi-threaded workload that are very allocation intensive nor do they directly address non-uniform memory access (NUMA) concerns.

For graph analytics applications memory allocation is generally restricted to two cases:

- allocations in the runtime (including library data structures)
- allocations in an activity to track per-activity state.

For the first case, the Galois runtime system uses a **slab allocator**, which allocates memory from pools of fixed-size blocks. This allocator is scalable but cannot handle variable-sized blocks efficently due to the overhead of managing fragmentation.

The slab allocator has a **separate allocator** for each block size and a **central page pool**, which contains huge pages allocated from the operating system. Each thread maintain a free list of blocks. Blocks are allocated first from the free list. If the list is empty, the thread acquires a page from the page pool and **uses bump-pointer allocation to divide the page into blocks**.

The second case, the Galois uses a **bump-pointer region allocator**.

Initialize the page pool, each application preallocates some number of pages prior to parallel execution.

Each activity executes on a thread, which has its own instance of the bump-pointer allocator, and reused between iterations on a thread.

#### Topology-aware synchronization

Communication paterns are topology-aware, so that the most common synchronizaiton is only between cores on the same package and share the same L3 cache.

The runtime uses a hybrid barrier where a tree topology is built across packages, but threads in a package communicate via a shared counter. This is about twice as fast as the classic MCS tree barrier.



### Code size optimizations

Since task can create new tasks, the support code for an operator must check **if new tasks were created** and if so **hand them to the scheduler**. This check requires only about 4 instructions, this amounts to almost 2% of the number instructions in an average SSSP task. For applications with fine-grain tasks, generality can **quickly choke performance**.

To reduce this overhead, Galois does not generate code for features that are not used by an operator. It use a **collection of type traits that statically communicate the features of the programming model** not needed by an operator to the runtime system.

Tight loops are more likely to fit in the trace cache or the L1 instruction cache. For very short operators, such as one in SSSP or BFS, this can result in a sizeable performance improvement.

These kinds of code specialization optimizations reduce the overhead of dynamic task creation, priority schduling and load balancing for SSSP to about 140 in-structions per activity; about half of which comes from the priority scheduler.



## Evaluation

![image-20210812094812950](https://img.sanzo.top/img/paper/image-20210812094812950.png)



Figure 9a shows that Galois is faster than Ligra and PowerGraph serveral orders of magnitude.

Figure 9b shows that performance of Ligra-g is roughly comparable to Ligra. PowerGraph-g is mostly better than PowerGraph, this can tell us better programs that can be written when the programmnig model is rich enough. (Ligra-g and PowerGraph-g is implementations of those DSLs in Galois).

Comparison between the two figure, most of the ratio in Figure 9a are greater than those in Figure 9b, but in the behavior of PowerGraph with PageRank on the road graph, The Galois improvenment is about 10X while PowerGraph-g improvement is about 50X. This suggest that the Galois application of PageRank, which is **pull-base, is not good as push-base algorithm used by PowerGraph, on the road graph.**

![image-20210812120126645](https://img.sanzo.top/img/paper/image-20210812120126645.png)



![image-20210812114623224](https://img.sanzo.top/img/paper/image-20210812114623224.png)





![image-20210812115156230](https://img.sanzo.top/img/paper/image-20210812115156230.png)







![image-20210812121431446](https://img.sanzo.top/img/paper/image-20210812121431446.png)





<!-- Q.E.D. -->