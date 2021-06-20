---
title: Linux命令
katex: true
date: 2021-06-17 15:54:40
updated: 2021-06-17 15:54:40
tags: command
categories: Linux
---



<!-- more -->

---

## 用户管理

```bash
# 创建用户sanzo，指定home目录和登陆的shell
useradd -d /home/sanzo -s /bin/bash -m sanzo

# 设置登录密码
passwd sanzo

# 添加sudo组
usermod -a -G sudo sanzo

# 删除用户
sudo userdel -r test
```



## 进程管理

### 后台执行

```bash
# 查看后台任务
jobs

# 前台执行任务
fg %np's

# 继续在后台执行挂起的任务
bg %n
 
# 挂起任务
ctrl+z

# 杀掉后台任务
kill %n

# 从当前shell移除
disown -h %1

# 后台执行
nohup ./xx.exe > log 2>&1 &
```



### 查找/终止进程

```bash
# 查看占用端口的PID
lsof -i:port
netstat -tunpl | grep port

# 查找指定名称的进程
ps -ef | grep xxx

# 获取指定名称进程的pid
ps -ef | grep free | grep -v grep | awk '{print $2}'

# 终止进程
ps -ef | grep free | grep -v grep | awk '{print $2}' | xargs kill

# 终止所有指定名称的进程
killall xxx
```

终止指定名称的进程：[kill.sh](https://github.com/Sanzo00/files/blob/master/shell/kill.sh)



```bash
# check input args
if [ $# -ne 1 ]; then
  echo "Usage: ./$0 xxx"
  exit 1
fi

echo "kill all $1*"

ps -ef | grep $1 | grep -v grep | grep -v kill.sh

pids=$(ps -ef | grep $1 | grep -v grep | grep -v kill.sh | awk '{print $2}')
#echo "pids:"
#echo $pids


if test -z $pids; then
  echo "$1 is alread killed!"
else
  for pid in $pids
  do
    echo "kill $pid"
    kill -9 $pid
  done
fi
```



## 常用命令

### wc

```bash
# 查看文件的行数
wc -l data.txt

# 查看./xx目录下.h文件的行数
find ./xx -name "*.h" | xargs wc -l
```



### date

  ```bash
# 日期
date

# 格式化显示
date +%Y-%m-%d
date +%H:%m
  ```

### cal

  ```bash
# 显示本月的日历
$ cal

# 显示2020年的日历
$ cal 2020

# 显示2020年5月的日历
$ cal 5 2020
  ```



### ssh

```bash
# 将远端服务器10.1.1.1的8888端口映射到本地的8888端口
ssh -L8888:localhost:8888 root@10.1.1.1
```



### head/tail

```bash
# 前1000行
head -n 1000 input.txt > output.txt

# 后1000行
tail -n 1000 input.txt > output.txt


# 第6-10行
 head -n 10 input.txt | tail -n 5
```



### grep

```bash
# 查找当前目录下所有包含'void main()'的文件
grep -rn "void main()"  ./
```



### gzip

```bash
# 解压到DIR目录
gzip xxx.gz -d DIR
```



### tar

```bash
# 解压到DIR目录
tar -xzvf xx.tar.gz -C DIR
```

<!-- Q.E.D. -->