---
title: git笔记
katex: true
typora-copy-images-to: ..\..\img\blog\git
date: 2021-07-11 00:10:10
updated: 2023-01-12 10:10:10
tags: git
categories: Blog
toc: true
---

git迷路指南

<!-- more -->

## Commit格式

```bash
feat: 新增 feature
fix: 修复 bug
docs: 仅仅修改了文档，比如 README, CHANGELOG, CONTRIBUTE等等
style: 仅仅修改了空格、格式缩进、逗号等等，不改变代码逻辑
refactor: 代码重构，没有加新功能或者修复 bug
perf: 优化相关，比如提升性能、体验
test: 测试用例，包括单元测试、集成测试等
chore: 改变构建流程、或者增加依赖库、工具等
revert: 回滚到上一个版本
```



## 常用命令

[Version Control（Git）](https://missing.csail.mit.edu/2020/version-control/)

```shell
# 查看hash对应的文件内容
git cat-file -p <hash>

# 以graph的格式展示log信息
git log --all --graph --decorate
git log --all --graph --decorate --oneline

# 查看文件的修改
git diff <filename>
git diff master <filename>
git diff <branch> <branch> <filename>
git diff <hash> <hash> <filename>
git diff --cached

# 切换分支
git checkout <branch>
git checkout -b <branch> # 新建分支并切换
git checkout <filenam> # 丢弃修改

# 分支合并
git merge <branch>

# 删除分支
git branch -d <branch>
git push origin --delete <branch>
git push origin :<branch>

# 设置upstream
git branch --set-upstream-to=origin/master

# 同步
git remote add <name> <url>
git push <name> <local branch>:<remote branch>
git pull <name> <remote branch>:<local branch>

# 仅选择需要add的行
git add -p <filename>

# 查看修改情况
git blame <filename> # 查看修改对应的id
git show <hash> # 查看commit信息

# 临时保存
git stash
git stash --include-untracked
git stash list
git stash show -p stash@{0}
git stash drop stash@{0}
git stash pop


# fork后的同步
# 设置upstream
git remote add upstream https://github.com/xxx/xxx.git
# 同步原仓库的更新
git fetch upstream
# 合并
git checkout master
git merge upstream/master

# submodule 
git submodule update --init --recursive
git submodule add your_repository.git
```



## 工作流

```bash
# 创建本地分支
git checkout -b my-feature

# 同步到remote
git push origin my-feature

# 将remote main的分支同步到本地分支
git checkout main
git pull origin main
git checkout my-feature
git rebase main
git push -f origin my-feature

# main合并pull request (squash and merge)
git checkout main
git merge --squash my-feature

# 删除分支
git checkout main
git branch -d my-feature
git push origin --delete my-feature
```





[git-简明指南](http://rogerdudler.github.io/git-guide/index.zh.html)

## 环境配置

- 配置用户信息

  ```bash
  git config --global user.name "Sanzo00"
  git config --global user.email "arrangeman@163.com"
  ```



- 生成ssh-key

  ```bash
  ssh-keygen -t rsa -C "arrangeman@163.com"
  ```

  将生成的公钥文件`~/.ssh/id_rsa.pub`添加到Github上。



## 版本回退

1. 修改文件后提交修改到版本库

   ```bash
   git add .
   git commit -m "xxx"
   ```

2. 查看历史版本

   ```bash
   git log # 显示最近到最远的提交
   git reflog # 显示所有执行过的命令
   ```

3. 回退到历史版本

   ```bash
   # 回到上一个版本
   git reset --hard HEAD^
   
   # 回到上上一个版本
   git reset --hard HEAD^^
   
   # 回到上一个版本 (同上)
   git reset --hard HEAD~1
   
   # 回到制定版本
   git reset --hard commit_id
   ```



## 工作区和暂存区

1. 工作区: 存放项目的目录

2. 暂存区

   ```bash
   # 将文件的修改添加到暂存区中
   git add "file"
   # 把暂存区的修改提交到分支
   git commit
   ```

   

## 撤销修改

```bash
# 本地修改没有git add到暂存区, 回退到上一个git add或git commit
git checkout -- <file>

# 本地修改已经git add到暂存区, 撤销本次git add, 同时撤销本次修改
git reset HEAD <file>
git checkout -- <file>
```



## 删除文件

1. 准备工作

   ```bash
   # 在工作区新建test文件
   touch test
   # 添加到暂存区
   git add test
   # 提交到分支
   git commit -m "add test"
   
   # 在本地删除test
   rm test
   # 工作区和版本库不一致
   git status
   ```

2. 确定删除文件test

   ```bash
   git rm test
   # git add test 等价
   git commit -m "remove test"
   ```

3. 恢复工作区文件(误删)

   ```bash
   git checkout -- <file>
   ```

4. 只删除记录中的文件，本地不删除

   ```bash
   git rm --cached <file>
   ```

   



## 远程仓库

1. 添加远程库

   ```bash
   # 初始化本地目录为git仓库
   git init
   # 关联一个远程库
   git remote add origin git@github.com:your_name/repo_name.git
   git push --set-upstream origin master
   # 本地同步远程仓库
   git pull origin master
   # 提交到远程仓库
   git push origin master
   ```

2. 修改远程目录

   ```bash
   git remote set-url origin git@github.com:your_name/repo_name.git
   ```

   

3. 克隆远程库

   ```bash
   git clone git@github.com:your_name/repo_name.git
   ```

   

## 本地仓库

本地仓库可以用于本地端的同步，例如将本地文件定时同步到硬盘这样的场景。

比如本地的文件夹为`files`。

```shell
# 将文件夹初始化为git目录。
git init

# 导出 files.git 目录
git clone --bare files files.git

# 把 files.git 放到硬盘中。
scp -r files.git /media/sanzo/path/

# 添加远程目录
git remote add origin g/media/sanzo/path/files.git
git push --set-upstream origin master

# 同步
git push
```





## 创建与合并分支

1. 创建新分支

   ```bash
   # 创建dev分支
   git branch dev
   # 切换分支
   git checkout dev
   # 查看当前分支
   git branch
   # 查看所有分支
   git branch -a
   ```

2. 合并分支

   ```bash
   # 切换到主分支, 切换前要git commit
   git checkout master
   # 合并dev到当前分支
   git merge dev
   # 删除dev分支
   git branch -d dev
   ```



## 解决冲突

当master和dev同时修改文件, 在git merge时会出现冲突, 需要手动解决冲突, 重新提交.

```bash
# 查看冲突信息
git status
# 打开冲突文件
<<<<<<< HEAD
5
=======
five
>>>>>>> dev

# <<<<<<<, =======, >>>>>>>表示不同的分支, 手动修改之后重新提交
git add <file>
git commit -m "conflict fixed"

#删除dev分支
git　branch -d dev

#查看分支合并图
git log --graph
```





## 分支管理

```git merge```, 在处理合并时如果可以, ```git```会使用```Fast forward```模式, 删除分支后会丢掉分支信息

```no-ff```强制禁止```Fast forward```, 在合并的时候多出一个```commit```记录, 保存分支信息

```bash
# 不使用 Fast forward模式合并分支
git merge --no-ff -m "merge with no-ff" dev
# 查看分区合并
git log --graph --pretty=oneline --abbrev-commit	
```



## Bug分支

当dev分支的工作未完成, 你需要紧急修复buf, 这时可以把当前分支暂时储存起来. 完成其他工作之后, 可以恢复现场继续工作.

```bash
# 储存现场
git stash

# 在master下新建分支并切换
git chekcout master
git checkout -b <branch>

# 完成工作后提交
git add <file>
git commit -m ""

# 回到之前分支
git checkout <branch>

# 查看保存的工作现场
git stash list

# 恢复现场
	## 1.恢复并删除 
	git stash pop
	
	## 2.恢复, 删除
	git stash apply stash@{0}
	git stash drop stash@{0}
```

在上面bug分支修复的错误, 在当前dev上同样也存在问题, 可以使用```cherry-pick```复制一个```commit```, 同事```git```会新创建一个```commit```

```bash
git cherry-pick commit_id
```

更简单的, 可以先用```git stash```报工作现场储存起来, 然后在当前分支修复```bug``` 之后恢复现场继续工作.





## Feature分支

当需要添加新功能时, 可以创建feature分支, 测试完成之后, 再合并到当前分支.

```bash
# 创建feature分支
git checkout -b feature

#删除没有合并的分支
git branch -D feature
```





## 多人协作

```bash
# 查看远程仓库
git remote
git remote -v

# 将本地master分支推送到远程库
git push origin master

# 将远程库的dev分支创建到本地
git checkout -b dev origin/dev

# 多人向dev合并, 会出现冲突
# 将远程库dev分支, 同步到本地
git pull
# git pull失败, 没有和远程库链接
git branch --set-upstream-to =origin/dev dev
# git pull之后, 手动解决冲突, 然后上传
```



## Rebase

多次本地提交或从远端pull下来之后, 本地的版本库会同时有多个commit, 通过--graph查看会觉得混乱, 可以使用rebase, 将多个commit合并成一个, 使得分支变得顺滑~.

```bash
# 合并commit
git rebase

# 如果出现冲突, 需要解决冲突之后重新git rebase
git add .
git rebase --continue
```



## .gitignore

```bash
# 忽略特殊文件
.gitignore

# 查看file文件是否被ignore
git check-ignore -v <file>
```





## git服务器

> 安装git

```bash
sudo apt install git
```



> 新建git用户

```bash
sudo adduser git
```



> 公钥登录

将设备的`id_rsa.pub`文件导入到服务器的`home/git/.ssh/authorized_keys`中。

如果本地的用户名和服务器的用户名不一致，需要配置`/home/user/.ssh/config`文件

```bash
Host server # 别名
    HostName 192.168.1.101 # 服务器ip
    User git	# 用户名
```



> 初始化

选定服务器的`/srv/git/`

```bash
# 新建目录作为git的工作目录
mkdir /srv/git

# 修改目录分组(必须)
sudo chown -R git:git /srv/git
```



> 禁用shell登录

编辑`/etc/passwd`

```bash
git:x:1002:1002:,,,:/home/git:/bin/bash
```

改为：

```bash
git:x:1002:1002:,,,:/home/git:/usr/bin/git-shell
```



> 新建仓库

```bash
sudo git init --bare /srv/git/sample.git
```

也可以将本地的git项目上传到服务器：

```bash
# 首先将本地的项目导出为.git目录
git clone --bare project project.git
# 相当于直接复制.git目录
cp -Rf project/.git project.git

# 上传到服务器
scp -r project.git git@server:/srv/git
```



> 克隆项目

```bash
git clone git@server:/srv/git/sample.git
git clone git@server:/srv/git/project.git
```





## 空分支

```bash
# 创建空分支 empty
git checkout --orphan empty

# 删除当前目录文件
git rm -rf .

# 提交分支
touch README.md
git add README.md
git commit -m "new branch"

# 查看所有分支
git branch -a
```





<!-- Q.E.D. -->