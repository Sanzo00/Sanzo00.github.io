---
title: 智能计算系统：实验5
katex: true
typora-copy-images-to: ../../img
date: 2021-12-03 18:00:42
updated: 2021-12-03 18:00:42
tags:
  - lab
  - bcl
  - op
categories:
  - AI-Computing-Systems
---



## BCL算子开发与集成

本实验通过使用智能编程语言进行算子开发，对高性能库算子进行扩展，并最终集成到编程框架中。

使用智能编程语言开发用户自定义的算子`PowerDifference`，通过高性能库`PluginOp`扩展算子，并和高性能库原有的算子一起集成到编程框架`TensorFlow`中，进而将训练好的风格迁移网络模型高效的运行在DLP硬件上。

实验工作量：约150行代码，约需10小时。

![image-20211207231705012](https://img.sanzo.top/img/znjs/image-20211207231705012.png)





具体实验内容包括：

1. Kernel实现：采用智能编程语言BCL实现PowerDifference算子的计算逻辑并进行正确性测试。
2. 框架算子集成：通过高性能库PluginOp的接口对PowerDifference算子进行封装，使其调用方式和高性能库原有算子一致，将封装后的算子集成到TensorFlow编程框架中并进行测试，保证其精度和功能正确行。
3. 模型在线推断：通过TensorFlow框架的接口，在内部高性能库CNML和运行时库CNRT的配合下，完成对风格迁移模型的在线推理，并生成离线模型。
4. 模型离线推断：采用运行时库CNRT的接口编写应用程序，完成离线推理，并将其结果和在线推理以及4.4节中的模型推断进行性能对比。

```bash
实验步骤：
1、环境变量初始化：先进入env/，执行source env.sh; 再进入tensorflow-v1.10/,执行source env.sh
2、bangc算子填写：补齐src/bangc/PluginPowerDifferenceOp/plugin_power_difference_kernel.h,plgin_power_difference_kernel.mlu
   和powerDiff.cpp，执行make.sh进行编译，运行power_diff_test测试
3、集成到cnplugin: 补齐src/bangc/PluginPowerDifferenceOp/cnplugin.h和plugin_power_difference_op.cc，将整个PluginPowerDifferenceOp文件夹
   复制到env/Cambricon-CNPlugin-MLU270/pluginops,在Cambricon-CNPlugin-MLU270目录下执行build_cnplugin.sh重新编译cnplugin;
   编译完成后将build/libcnplugin.so和cnplugin.h分别拷入到env/neuware/lib64和env/neuware/include中。
 注：cnplugin.h中PowerDifference算子的声明可以参考其他算子声明来进行添加，plugin_power_difference_op.cc中的算子函数定义可以参考pluginops目录下其他算子的定义实现
4、集成到tensorflow: 补齐src/tf-implementation/tf-add-power-diff/power_difference.cc和cwise_op_power_difference_mlu.h，
   按照readme.txt提示拷入到对应文件夹，重新编译tensorflow
5、框架算子测试：补齐src/online_mlu/power_difference_test_bcl.py
6、在线推理和生成离线模型：补齐src/online_mlu/power_difference_test_bcl.pysrc/online_mlu/transform_mlu.py
7、离线推理：补齐src/offline/src/inference.cpp

自动测试需要提交的文件：
├── inference.cpp
├── libcnplugin.so      // 重新编译cnplugin生成的库文件
├── plugin_power_difference_kernel.h
├── plugin_power_difference_kernel.mlu
├── powerDiff.cpp
├── power_difference_test_bcl.py
├── tensorflow_mlu-1.14.0-cp27-cp27mu-linux_x86_64.whl      // 重新编译tensorflow生成的whl
└── transform_mlu.py
将以上文件压缩成zip格式进行提交
```





### Kernel实现

补全`plugin_power_difference_kernel.h`,`plugin_power_difference_kernel.mlu`。

> kernel程序编写

```cpp
// file: plugin_power_difference_kernel.mlu
 2  // 定义常量
 3  #define ONELINE 256
 4  
 5  __mlu_entry__ void PowerDifferenceKernel (half* input1, half* input2, int pow, half*output, int len)
 6  {
 7    int quotient = len / ONELINE;
 8    __bang_printf ("%d %d\n", pow, len);
 9    int rem = len % ONELINE;
10    
11    // 声明NRAM空间
12    __nram__ half input1_nram [ONELINE];
13    __nram__ half input2_nram [ONELINE];
14    
15    if (rem != 0)
16    {
17      quotient +=1;
18    }
19    for (int i = 0; i < quotient; i ++)
20    {
21      //TODO：内存拷贝，从GDRAM的（input1 + i * ONELINE）位置开始，拷贝ONELINE * sizeof(half)大小的数据到input1_nram空间中
22      __memcpy(___________________________);
23      __memcpy(___________________________);
24      //TODO：按元素减法操作，将input1_nram和input2_nram的对应元素相减并将结果存储在input1_nram中
25      __bang_sub (_________________________);
26      //TODO：NRAM中两个数据块的数据拷贝操作
27      __memcpy(___________________________);
28      for (int j = 0; j < pow − 1; j ++)
29      {
30        //TODO：按元素乘法操作
31        __bang_mul (_______________________);
32      }
33      //TODO：内存拷贝，从NRAM中将计算的结果拷贝至GDRAM中
34      __memcpy(___________________________);
35    }
36  }
```



实验手册的一处错误：

![](https://img.sanzo.top/img/znjs/image-20211204130448896.png)



```cpp
// page 185
__memcpy(void *dst, void *src, int32_t Bytes, mluMemcpyDirection_t direct);

// page 191
void __bang_printf (const char *fmt [, type a1] [,type a2] [, type a3] …[, type a16]);

// page 124
void __bang_sub (half* dst, half* src0, half* src1, int elem_count);
void __bang_sub (float* dst, float* src0, float* src1, int elem_count);

// page 117
void __bang_mul (half* dst, half* src0, half* src1, int elem_count);
void __bang_mul (float* dst, float* src0, float* src1, int elem_count);
```



> 运行时程序编写

补全`powerDiff.cpp`。

```cpp
// file: powerDiff.cpp
 2  #include <stdlib.h>
 3  #include "cnrt.h"
 4  #include "cnrt_data.h"
 5  #include "stdio.h"
 6  #ifdef __cplusplus
 7  extern "C" {
 8  #endif
 9  void PowerDifferenceKernel (half* input1, half* input2, int32_t pow, half* output, int32_t len);
10  # ifdef __cplusplus
11  }
12  #endif
13  void PowerDifferenceKernel (half* input1, half* input2, int32_t pow, half* output, int32_t len);
14  
15  int MLUPowerDifferenceOp(float* input1, float* input2, int pow, float*output, int dims_a) {
16      // 初始化
17      ...
18      if (CNRT_RET_SUCCESS != cnrtMalloc ((void**)&mlu_input1, dims_a * sizeof (half))) {
19          printf ("cnrtMalloc Failed !\n");
20          exit (−1);
21      }
22      ...
23      //TODO: 将两个输入拷贝到设备端
24      cnrtMemcpy(____________,CNRT_MEM_TRANS_DIR_HOST2DEV);
25      cnrtMemcpy(____________,CNRT_MEM_TRANS_DIR_HOST2DEV);
26      // Kernel 参数
27      cnrtKernelParamsBuffer_t params;
28      cnrtGetKernelParamsBuffer(&params);
29      cnrtKernelParamsBufferAddParam (params, &mlu_input1, sizeof (half *));
30      ...
31      //TODO：启动Kernel
32      cnrtInvokeKernel_V2 (_______________________________);
33      //TODO：将计算结果拷回Host
34      cnrtMemcpy(____________,CNRT_MEM_TRANS_DIR_DEV2HOST);
35      cnrtConvertHalfToFloatArray (_______________________);
36      // 释放内存
37      cnrtDestroy();
38      ...
39      return 0;
40  }
```



```cpp
// page 28
cnrtMemcpy(output_half, mlu_output, sizeof(half), CNRT_MEM_TRANS_DIR_DEV2HOST);

// page 28
cnrtInvokeKernel_V2((void *)(&L2LossKernel), dim, params, ft, pQueue);
```

> 编译运行

![image-20211207235324904](https://img.sanzo.top/img/znjs/image-20211207235324904.png)



### 框架算子集成

为了使算子往TensorFlow中集成更加模块化，这里对算子进行了多个层次的封装，如下图。

![image-20211207235558729](https://img.sanzo.top/img/znjs/image-20211207235558729.png)

自底向上分为以下几个层次：

- MLULib层：对CNML和CNPlugin算子的直接封装，封装的结果供MLUOp层调用，这一层封装的目的是将高层调用和底层的计算库的接口实现有效的隔离，避免相互干扰。
- 封装MLUOp层：负责TensorFlow算子的DLP实现，调用MLULib实现算子后供MLUStream层调用。可以只调用单独的MLULib算子，也可以调用多个MLULib算子拼接为更复杂的TensorFlow算子。
- MLUStream层：与MLUOpKernel类接口相关联，负责MLU算子的实例化并与运行时队列结合。
- 封装MLUOpKernel：定义并组册最终运行的算子类MLUOpKernel，集成TensorFLow中的OpKernel，作为与TensorFlow算子层的接口。
- 算子注册：注册最终的算子供上层调用。

MLULib层的调用：

![image-20211208002114236](https://img.sanzo.top/img/znjs/image-20211208002114236.png)

> 算子融合

根据实验手册补全`plugin_power_difference_op.cc`和`cnplugin.h`。 

`cnmlPluginPowerDifferenceOpParam_t`的实现可以参考`cnplugin.h`中其他算子的实现。

![image-20211204151424761](https://img.sanzo.top/img/znjs/image-20211204151424761.png)



cnmlCreatePluginPowerDifferenceOp函数的参数顺序可以参考`tf-implementation/mlu_lib_ops.cc`文件的这个函数调用的参数顺序。

![image-20211204205151238](https://img.sanzo.top/img/znjs/image-20211204205151238.png)

![image-20211203213305385](https://img.sanzo.top/img/znjs/image-20211203213305385.png)





![image-20211203213852692](https://img.sanzo.top/img/znjs/image-20211203213852692.png)





![image-20211203213943532](https://img.sanzo.top/img/znjs/image-20211203213943532.png)



编译生成`.so`文件：

```bash
1. 将整个PluginPowerDifferenceOp文件夹复制到env/Cambricon-CNPlugin-MLU270/pluginops
2. 在Cambricon-CNPlugin-MLU270目录下执行build_cnplugin.sh重新编译cnplugin;
3. 编译完成后将build/libcnplugin.so和cnplugin.h分别拷入到env/neuware/lib64和env/neuware/include中。
```



> 集成到tensorflow

补全cwise_op_power_difference_mlu.h，这个和实验4-4注册算子一样，直接拿来用就行。

补全`powerdifference.cc`。

```cpp
 1  // file: tensorflow / stream_executor / mlu / mlu_api / ops / mlu_ops.h
 2  DECLARE_OP_CLASS(MLUPowerDifference); // 添加算子类的申明
 3  
 4  // file: tensorflow / stream_executor / mlu / mlu_api / ops / power_difference.cc
 5  Status MLUPowerDifference:: CreateMLUOp(std:: vector <MLUTensor *> &inputs, std:: vector <MLUTensor *> &outputs, void *param) {
 6    TF_PARAMS_CHECK(inputs.size() > 1, "Missing input");
 7    TF_PARAMS_CHECK(outputs.size() > 0, "Missing output");
 8    MLUBaseOp *power_difference_op_ptr = nullptr;
 9    MLUTensor *input1 = inputs.at (0);
10    MLUTensor *input2 = inputs.at (1);
11    int power_c = *((int*)param);
12    MLUTensor *output = outputs.at (0);
13    
14    //TODO: 数据准备
15    _______________________________
16    _______________________________
17    _______________________________
18    //TODO：创建MLUTensor
19    TF_STATUS_CHECK(lib::CreateMLUTensor(_______________________));
20    //TODO: 创建BroadcastOp
21    TF_STATUS_CHECK(lib:: CreateBroadcastOp(_____________________));
22    //TODO：调用MLULib层实现好的CreatePowerDifferenceOp
23    TF_STATUS_CHECK(lib:: CreatePowerDifferenceOp(_______________));
24    base_ops_.push_back(power_difference_op_ptr);
25    extra_ = static_cast <void*>(op_index);
26    return Status::OK();
27  }
28  
29  Status MLUPowerDifference::Compute(const std:: vector<void *> &inputs, const std::vector<void *> &outputs, cnrtQueue_t queue) {
30    //TODO：数据准备
31    _______________________________
32    _______________________________
33    _______________________________
34    //TODO: 调用ComputeBroadCastOp
35    lib::ComputeBroadCastOp(____________________________________);
36    //TODO：调用MLULib层实现好的ComputePowerDifferenceOp
37    TF_STATUS_CHECK(lib:: ComputePowerDifferenceOp(______________));
38    TF_CNRT_CHECK(cnrtSyncQueue(queue));
39    //TODO：释放内存
40    _______________________________
41    _______________________________
42    _______________________________
43    return Status::OK();
44  }
```

`powerdifference.cc`的代码补全可以参考`env/tensorflow-v1.10/tensorflow/stream_executor/mlu/mlu_api/ops/squared_difference.cc`，唯一不同的是PowerDifference需要计算tensor的length。

![image-20211208101730956](https://img.sanzo.top/img/znjs/image-20211208101730956.png)





按照readme.txt提示拷入到对应文件夹，重新编译tensorflow。

```bash
/opt/code_chap_5_student/env/tensorflow-v1.10/tensorflow/core/kernels/cwise_op_power_difference*
/opt/code_chap_5_student/env/tensorflow-v1.10/tensorflow/core/kernels/BUILD
/opt/code_chap_5_student/env/tensorflow-v1.10/tensorflow/stream_executor/mlu/mlu_stream.h
/opt/code_chap_5_student/env/tensorflow-v1.10/tensorflow/stream_executor/mlu/mlu_api/lib_ops/mlu_lib_ops.*
/opt/code_chap_5_student/env/tensorflow-v1.10/tensorflow/stream_executor/mlu/mlu_api/ops/mlu_ops.h
/opt/code_chap_5_student/env/tensorflow-v1.10/tensorflow/stream_executor/mlu/mlu_api/ops/power_difference.cc
/opt/code_chap_5_student/env/tensorflow-v1.10/tensorflow/core/ops/math_ops.cc
```



下面这个是一个简单的脚本文件，完成实验5-1中所有的文件复制和编译命令，没有检查命令的返回值，用的时候小心。

```bash
# copy to pluginops
dir1=/opt/code_chap_5_student/code_chap_5_1_student/src/bangc/PluginPowerDifferenceOp
dir2=/opt/code_chap_5_student/env/Cambricon-CNPlugin-MLU270/pluginops
cp -r $dir1 $dir2 

# build cnplugin
cd /opt/code_chap_5_student/env/Cambricon-CNPlugin-MLU270
./build_cnplugin.sh

# copy to env/nueware
so_file=/opt/code_chap_5_student/env/Cambricon-CNPlugin-MLU270/build/libcnplugin.so
lib_path=/opt/code_chap_5_student/env/neuware/lib64/
cp $so_file $lib_path

# copy to tensorflow
dir3=/opt/code_chap_5_student/code_chap_5_1_student/src/tf-implementation/tf-add-power-diff
dir4=/opt/code_chap_5_student/env/tensorflow-v1.10/tensorflow

cp $dir3/cwise_op_power_difference* $dir4/core/kernels/
cp $dir3/BUILD $dir4/core/kernels/
cp $dir3/mlu_stream.h $dir4/stream_executor/mlu/
cp $dir3/mlu_lib_ops.* $dir4/stream_executor/mlu/mlu_api/lib_ops/
cp $dir3/mlu_ops.h $dir4/stream_executor/mlu/mlu_api/ops/
cp $dir3/power_difference.cc $dir4/stream_executor/mlu/mlu_api/ops/
cp $dir3/math_ops.cc $dir4/core/ops/

# build tensorflow
dir_tf=/opt/code_chap_5_student/env/tensorflow-v1.10
cd $dir_tf
./build_tensorflow-v1.10_mlu.sh
```



编译结果如下：

```bash
INFO: Elapsed time: 1909.924s, Critical Path: 192.78s
INFO: 9895 processes: 9895 local.
INFO: Build completed successfully, 10553 total actions

...

Installing collected packages: tensorflow-mlu
  Attempting uninstall: tensorflow-mlu
    Found existing installation: tensorflow-mlu 1.14.0
    Uninstalling tensorflow-mlu-1.14.0:
      Successfully uninstalled tensorflow-mlu-1.14.0
Successfully installed tensorflow-mlu-1.14.0
```



> 算子测试

补齐`online_mlu/power_difference_test_bcl.py`

```bash
comput BCL op cost 147.653102875ms
comput op cost 255.165815353ms
err rate= 0.06631744635811314
```



### 模型在线推断

参考实验4-4的`transform_cpu.py`补全`transform_mlu.py`。

```python
config.mlu_options.data_parallelism = 1
config.mlu_options.model_parallelism = 1
config.mlu_options.core_num = 16
config.mlu_options.core_version = "MLU270"
config.mlu_options.precision = "int8"
config.mlu_options.save_offline_model = True
```

```python
input_pow = np.array(2, dtype=float)
ret = sess.run(output_tensor, feed_dict={input_tensor:[X], input_tensor_pow: input_pow})
```

底层算子在实现的时候是通过dim_size来确定的power_value，所以传入的是一个张量。

![image-20211205101509305](https://img.sanzo.top/img/znjs/image-20211205101509305.png)



### 模型离线推断

补全`inference.cpp`文件，需要对输入数据的格式进行转换float32 to flaot16，另外还需要对输入的数据的维度进行变换。

```cpp
extern cnrtRet_t cnrtTransDataOrder(void *src_addr,
                                    cnrtDataType_t data_type,
                                    void *dst_addr,
                                    int dimNum,
                                    int dimValues[],
                                    int dimOrder[]);

extern CNRT_DLL_API cnrtRet_t cnrtCastDataType(void *src_addr,
                                               cnrtDataType_t src_data_type,
                                               void *dst_addr,
                                               cnrtDataType_t dst_data_type,
                                               int data_num,
                                               cnrtQuantizedParam_t param);

```

name没有给出来，可以参考文件`models/offline_models/udnie_int8_power_diff.cambricon_twins`

```cpp
cnrtExtractFunction(&function, model, "subnet0");
```

代码补全之后，进入build文件夹，重新编译代码，然后运行`run.sh`进行测试。

```cmake
cd build
cmake ..
make
```



![image-20211207210603424](https://img.sanzo.top/img/znjs/image-20211207210603424.png)





## BCL性能优化实验

下图为MLU加速卡的架构，有4个Cluster，每个Cluster有4个Core，内存方面：全局内存GDRAM，每个Cluster的SRAM，每个Core有NRAM和WRAM。

![image-20211205151914267](https://img.sanzo.top/img/znjs/image-20211205151914267.png)



### 标量操作

每个DLP的计算核都有自己的NRAM，虽然相对于GDRAM，内存空间较小，但是其具有更高的读写带宽和更低的延迟。

下面的标量实现将矩阵全部读到NRAM中，然后循环进行计算，如果输入矩阵过大，则需要多次读写NRAM。

![image-20211205151741780](https://img.sanzo.top/img/znjs/image-20211205151741780.png)





### 单核向量化

将输入矩阵A和B分别存放在DLP计算核的两个存储单元NRAM和WRAM，然后使用DLP的卷积指令做矩阵乘法计算。当矩阵B的规模很大时，需要分批次（N/256）拷贝，另外在使用卷积指令计算时，需要将矩阵转化为__bang_conv支持的格式（内存对齐）。

![image-20211205153135516](https://img.sanzo.top/img/znjs/image-20211205153135516.png)



![image-20211205154124143](https://img.sanzo.top/img/znjs/image-20211205154124143.png)



```cpp
void __memcpy (void* dst, void* src, int size, mluMemcpyDirection_t dir, 
               int dst_stride, int src_stride, int count);

void __bang_conv(float* dst, int16* src, int16* kernel, const int channel_input, 
                 const int height, const int width, 
                 const int kernel_height, const int kernel_width, 
                 const int stride_w, const int stride_h, 
                 const int channel_output, int fix_position);
```



### 多核并行化

以上的只调用用了DLP的一个计算核进行计算，DLP有16个核，可以通过并行计算的方式进一步优化计算速度。

基本思想是将输入矩阵的规模拆分成多份，并将每份分配给不同的计算和进行计算，最后再对计算结果进行合并。

每个计算核在读取数据的时候，根据自己的coreId来确定目标数据的GDRAM地址，并将自己负责的数据快拷入到NRAM中。

![image-20211205171502851](https://img.sanzo.top/img/znjs/image-20211205171502851.png)





### SRAM数据访问优化

多核并行的实现中使用了4个Cluster的16个核进行并行计算，而相同的Cluster中的核在从GDRAM中拷贝数据到各自的NRAM时，会争抢GDRAM到Cluster的带宽，导致数据读取速度降低。

每个Cluster又一个共享的SRAM，我们可以将矩阵B先从GDRAM拷贝到SRAM中，然后在分发给不同的核。这种方式可以避免GDRAM到Cluster的带宽竞争，同时SRAM的存取速度高于GDRAM，因此也可以降低访问延迟，提高数据读取速度。

本实验打破了数据访问核计算在时许上的独立性，因此需要进行同步操作。

![image-20211205152203343](https://img.sanzo.top/img/znjs/image-20211205152203343.png)

![image-20211205171622311](https://img.sanzo.top/img/znjs/image-20211205171622311.png)

![image-20211205171643330](https://img.sanzo.top/img/znjs/image-20211205171643330.png)





### 访寸和计算流水线优化

从下图可以看出，从GDRAM数据拷贝的时间较长，且数据的拷贝与计算串行，DLLP的利用率不高。针对这个问题可以将数据的拷贝和四个核的计算做流水处理，从而隐藏数据拷贝的时间。

![image-20211205152230322](https://img.sanzo.top/img/znjs/image-20211205152230322.png)



基本思想是将SRAM分成两个部分（S1和S2），轮流存放GDRAM的数据，即“乒乓操作”。

当GDRAM往S1拷贝完数据之后，计算核开始计算，同时GDRAM往S2拷贝数据；

当计算核计算完成，同时GDRAM往S2拷贝完数据之后，计算核开始处理S2的数据，同时GDRAM开始往S1拷贝数据。

通过以上操作可以隐藏GDRAM到SRAM的访问延迟。

![image-20211205152241077](https://img.sanzo.top/img/znjs/image-20211205152241077.png)



![image-20211205171808620](https://img.sanzo.top/img/znjs/image-20211205171808620.png)

![image-20211205171826141](https://img.sanzo.top/img/znjs/image-20211205171826141.png)





![image-20211207210628386](https://img.sanzo.top/img/znjs/image-20211207210628386.png)





##  参考资料

- [第五章实验手册](http://forum.cambricon.com/uploadfile/user/file/20210401/1617260738971059.pdf)
- [第八章-智能编程语言课件](https://novel.ict.ac.cn/download_aics/ch8.pdf)
- [BANG C开发者指南](http://forum.cambricon.com/uploadfile/user/file/20201125/1606289569710855.pdf)
- [CNRT离线模型示例程序](https://www.cambricon.com/docs/cnrt/user_guide_html/example/offline_mode.html)
- [以矩阵乘为例的BANG C编程实验](https://developer.cambricon.com/index/curriculum/expdetails/id/8/classid/8.html)
