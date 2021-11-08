---
title: hello hexo
katex: true
date: 2021-06-12 19:54:23
updated: 2021-06-12 19:54:23
tags:
  - hexo
  - shell
  - github actions
categories: Default
---

hexo基本命令、commit脚本、Github Actions自动部署

<!-- more -->

---

## hexo基本命令

```bash
# 创建Default/xx.md文件，文章title设为"hello world"
hexo new post -p Default/xx.md "hello world"

# 新建links页面
hexo new page links

# 清空缓存
hexo clean

# 生成静态文件
hexo generate

# 部署
hexo deploy
```

在执行`hexo deploy`之前需要配置仓库地址：

```bash
deploy:
  type: git
  repo: 你此前新建的仓库的链接 # https://github.com/Sanzo00/Sanzo00.github.io
  branch: master # 默认使用 master 分支
  message: Update Hexo Static Content # 自定义此次部署更新的说明
```



## commit脚本

```bash
commit=$1
if [ "$commit" = "" ];
then commit=":pencil: Update content"
fi
echo $commit
git add -A
git commit -m "$commit"
git push origin hexo
```

使用方法：

```bash
# 默认commit为 ”:pencil: Update content“
bash update.sh

# 指定commit为”update.sh“
bash update.sh "Add update.sh"
```



## 自动部署

在项目根目录创建文件`.github/workflows/gh-pages.yml`，将下面配置添加到文件中。

```bash
name: GitHub Pages
on:
  push:
    branches:
      - hexo
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
        with:
          submodules: true

      - name: Setup Node
        uses: actions/setup-node@v2
        with:
          node-version: "14.x"

      - run: yarn
      - run: yarn build

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
          publish_branch: master
          force_orphan: true
```

之后只需要向hexo分支push修改即可，github action会自动的进行构建，并将构建的文件同步到master分支。

```bash
bash update.sh "Add github actions"

# bash update.sh
```



## 插件

### pdf

https://github.com/superalsrk/hexo-pdf

```shell
{% pdf xx.pdf %}
```



<!-- Q.E.D. -->
