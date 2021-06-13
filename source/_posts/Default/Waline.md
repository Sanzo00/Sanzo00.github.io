---
title: 博客评论系统的搭建
katex: true
date: 2021-06-13 11:13:54
updated: 2021-06-13 11:13:54
tags: 
	- vercel
	- waline
	- leanCloud
categories: Default
---



评论系统使用的是Waline，服务端使用Vercel，数据存储使用LeanCloud.



<!-- more -->

---

使用Waline的主要原因是免费，而且支持评论通知（邮件、QQ、微信、TG）。

[效果展示，欢迎留言~: sanzo.top/about/#comment](https://sanzo.top/about/#comment)

## 搭建过程

具体的搭建过程参考：

[Waline快速上手](https://waline.js.org/guide/get-started.html)

[Waline评论通知](https://waline.js.org/guide/server/notification.html)



## 遇到的问题

在配置邮件通知时，必须设置以下环境变量：

| key          | value          |
| ------------ | -------------- |
| SMTP_SERVICE | 邮件服务提供商 |
| SMTP_USER    | 邮箱地址       |
| SMTP_PASS    | SMTP密码       |
| SITE_NAME    | 网站名称       |
| SITE_URL     | 网站地址       |

以下是选填的环境变量：


| key          | value    |
| ------------ | -------- |
| SENDER_NAME  | 发件人   |
| SENDER_EMAIL | 发件地址 |
| AUTHOR_EMAIL | 博主邮箱 |



这是我的邮件通知模板，需要添加在vercel项目的`index.js`中。

```javascript
const Application = require('@waline/vercel');

module.exports = Application({
    mailSubject: 'Hi {{parent.nick}}，您在博客「{{site.name}}」上的评论收到了回复',
    mailTemplate: `
      <div style="border-top:2px solid #12ADDB;box-shadow:0 1px 3px #AAAAAA;line-height:180%;padding:0 15px 12px;margin:50px auto;font-size:12px;">
        <div style="padding:0 12px 0 12px;margin-top:18px">
          <p>{{parent.nick}}，您曾发表评论：</p>
          <div style="background-color: #f5f5f5;padding: 10px 15px;margin:18px 0;word-wrap:break-word;">{{parent.comment | safe}}</div>
          <p><strong>{{self.nick}}</strong> 回复说：</p>
          <div style="background-color: #f5f5f5;padding: 10px 15px;margin:18px 0;word-wrap:break-word;">{{self.comment | safe}}</div>
          <p>
            <a style="text-decoration:none; color:#12addb" href="{{site.postUrl}}" target="_blank">前往原文查看完整的回复內容</a>
            ，欢迎再次光临
            <a style="text-decoration:none; color:#12addb" href="{{site.url}}" target="_blank">{{site.name}}</a>。
          </p>
          <br/>
        </div>
      <div style="border-top:1px solid #DDD; padding:13px 0 0 8px;">
      该邮件为系统自动发送的邮件，请勿直接回复。
      </div>
      <br/>
      </div>`,
      // mailSubjectAdmin: '您的博客「{{site.name}}」收到了新评论',
      mailSubjectAdmin: '{{self.nick}}发表了新的评论',
      mailTemplateAdmin: `
      <div style="border-top:2px solid #12ADDB;box-shadow:0 1px 3px #AAAAAA;line-height:180%;padding:0 15px 12px;margin:50px auto;font-size:12px;">
        <h2 style="border-bottom:1px solid #DDD;font-size:14px;font-weight:normal;padding:13px 0 10px 8px;">{{self.nick}}发表了新的评论:</h2>
        <div style="padding:0 12px 0 12px;margin-top:18px">
          <div style="background-color: #f5f5f5;padding: 10px 15px;margin:18px 0;word-wrap:break-word;">{{self.comment | safe}}</div>
          <p>email: {{self.mail}}</p>
          <p>link: {{self.link}}</p>
          <p><a style="text-decoration:none; color:#12addb" href="{{site.postUrl}}" target="_blank">前往原文查看完整的评论内容。</a></p>
          <br/>
        </div>
      <div style="border-top:1px solid #DDD; padding:13px 0 0 8px;">
      该邮件为系统自动发送的邮件，请勿直接回复。
      </div>
      <br/>
      </div>`  
});
```



<!-- Q.E.D. -->