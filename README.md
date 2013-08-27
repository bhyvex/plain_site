PlainSite
=========

A Simple Static Site Generator Inspired by Jekyll and Octopress.



## Getting Started

1. Install gem
  ```bash
  gem install plain_site
  ```

2. Init site
  ```bash
  cd my-site
  plain_site init
  ```
3. Create new post
  ```bash
  plain_site new_post demo-post "Hello,wolrd!This is the title!"
  ```
4. Preview site,open ```http://localhost:1990/``` in your browser
  ```bash
  plain_site serve
  ```
5. Build site static pages.
  ```bash
  plain_site build
  ```

## 特性
1. 类似于MVC的结构，通过```routes.rb```灵活组织输出页面路径及内容
2. build命令可通过Git Status，只生成被修改过的Post及Template对应的页面。

      _但只能是Post或Template是被直接配置在```routes.rb```中```data```和```template```项中。如果Post是在ERB代码中直接读出，而不是在```routes.rb```中```data```项中配置的，则不能被```build```命令识别，需要将```build_anyway```项设置成true。_
      
3. 通过serve命令，运行一个预览服务器，修改文件后可直接刷新浏览器看到结果。

## More
1. Run ```plain_site help``` for more command line options.
2. Run ```gem server``` to read plain_site rdoc.
3. RTFSC

## PlainSite目录结构
```
.
├── .git
├── .gitignore
├── .nojekyll
└── _src
    ├── assets
    ├── posts
    │   └── category
    │         └── 2012-12-25-hello-world.md
    ├── templates
    │   └── post.html
    ├── routes.rb
    └── config.yml
```

一个PlainSite站点目录，即是一个GitPages库目录。所以，如果将目录提交到GitPages后，目录中的静态文件都是可以通过Web方式访问到的。目录```_src```是PlainSite所专用的目录，注意，这个目录及其下的文件也是提交到Git并且可以通过Web访问的。下面是各子目录的用途：

1. ```posts```: 文章目录，目录下一个文件对应一条数据，通过目录组织它的类别(Category)
2. ```routes.rb```: 包含配置URL的Ruby文件，用于指定站点总共有多少种URL，每种URL返回的内容使用的数据（posts目录中的数据）及用来渲染的模板(templates下的ERB类型的文件)
3. ```templates```: 各种各样的ERB模板文件
4. ```assets```: 站点资源文件，build之后将被copy到站点根目录下。这是为了方便区别生成的页面与源文件。
                  如建议将```favicon.png```放在```_src/assets/favicon.png```，
                  build之后将被copy到```/favicon.png```。
5. ```config.yml```：站点的一些配置及信息，可以直接通过```PlainSite::Site#config```进行访问

## Basic Concepts

PlainSite 包含四个核心概念:
  
1. Post

      Plain text file under ```_src/posts/```,represents your article contents.
      ```PlainSite::Data::Post``` object in ruby.

2. Category

      Directory under  ```_src/posts/```.
      ```PlainSite::Data::Category``` object in ruby.
      
3. Template

      ERB template Under ```_src/templates/``` directory.
      
4. Routes

      A ruby script under ```_src/routes.rb```. 配置输出的URL路径规则.


**PlainSite会忽略名称以下划线开头的Post、Template文件或Category目录。**


### Post 和 Category

站点```_src/posts/```目录下一个文件代表一篇Post。Post文件的文件名通常为：
```
2011-02-28-hello-world.md
```
其中，```2011-02-28```为文章创建日期（可选）;```hello-world```为文章的slug（必须），通常被用在URL中，注意，同一目录下，slug不能重复;```.md``` 部分则表示Post内容类型，目前PlainSite支持Markdown与HTML两种文件格式，扩展名分别为```md```与```html```。

Post文件路径则代表了它的Category，你可以通过目录来组织文章分类，如：
```
_src/posts/programming/2011-02-28-hello-world.md
_src/posts/essays/2013-04-22-life-is-a-game.md
```
这里包含了```programming```与```essays```两个分类。Category目录下可以放一个YAML格式的```_meta.yml```文件，配置它的一些元信息，如```display_name```。
例如 ```_src/posts/programming/_meta.yml``` 文件内容：
```yaml
display_name: 编程
```

当然，你可以完全不用Category目录，将所有Post放到```_src/posts/```下面。

Post文件的slug与category组成了Post的```data_id```。


Post文件必须包含一个YAML-Front格式的Header，两个```---```之间的内容是YAML格式的Header信息。
并且Post至少要有```title```属性。Post内容中可以通过highlight标签使用代码高亮功能（不管对于Markdown格式还是HTML格式，都是使用相同格式的```<highlight></highlight>```标签）。
Post文件还支持内嵌ERB模板代码，运行时可以访问到当前Post对象自身，详见Ruby文档。
例如，Post 文件```_src/posts/programming/2011-02-28-hello-world.md```的内容：
```
---
title: Hello,world!
tags: [Ruby,Python,Java,Haskell]
---

**这里才是文章的内容!**

注意，highlight标签中，语言参数是必须提供的。

Ruby代码高亮：
<highlight ruby>
puts "Hello,world!"
</highlight>

Python，加个行号功能：
<highlight python linenos>
def hello():
  print("Hello")
</highlight>

PHP代码不需要加"<?php"的头，还可指定行号从几开始：
<highlight php linenos=20>
echo "PlainSite";
ob_flush();
</highlight>

如果代码中不包含换行，将自动输出成inline格式的<highlight ruby>puts "但你还是要指定语言"<highlight>

代码高亮就这么些功能了，没有其它的了。

文章发布时间是这个：<%=date%>
文章slug是这个：<%=slug%>
当前文章的URL是：<%=site.url_for self %>
分类：<%=category.display_name%>

YAML Header中的属性都可以通过Post对象的属性来访问：<%=title%>

```


### Routes 和 Templates
文件```_src/routes.rb```用来配置输出的URL路径规则。
执行时可以通过全局变量 ```$site``` 访问到当前的```PlainSite::Site```对象。
通过```$site.db```得到表示```_src/posts```的Root ```PlainSite::Data::Category```对象。
下面演示了最常用的功能，至于```$site.route```方法及分页、文章查询的细节请阅读rdoc文档或代码：

```ruby
# coding:utf-8

$site.route(
  url_pattern: 'index.html', # url_pattern 指定输出url路径（相对于站点根目录，不需要以'/'开头）
  template: 'index.html',    # template指定用来渲染页面的模板，值为_src/templates/下文件的名称
  # data表示用来传给template渲染的数据，如果为Array/PostList对象，则会将each item用template渲染输出多个页面。
  # template中context即为data指定的对象，可以通过属性名或key访问其值，如这里的'index.html'可以直接访问site和demo属性
  data: {site: $site, demo:123},
  build_anyway:true #是否每次执行build命令时都重新生成页面。默认build命令可以通过查看Git Status，只生成变更过的文件的相关页面。
)

$site.route( #生成指定的单个Post对应的页面
    url_pattern: 'about.html',
    data: $site.db / :about , # 得到 data_id为about的Post
    template: 'post.html'
)

$site.route( #生成essays分类个每一篇文章对应的页面
    # ur_pattern: '{date.year}/{date.month}/{date.day}/{slug}.html',
    url_pattern: '{data_id}.html', # url_pattern中支持变量替换，变量为data中指定的对象的属性或key
    data: 'essays/*', # 'essays/*' 这样的路径可以获取到essays这个Category可所有的post，返回PostList对象
    template: 'post.html'
)

$site.route(
    url_pattern: 'programming/{slug}.html',
    data: $site.db / :programming / :*, # 纯粹是'programming/*'的另一种写法
    template: 'post.html'
)

# $site.db.subs为_src/posts 下的所有分类目录,返回Category[]
$site.db.subs.each do |cat|
    $site.route(
        url_pattern: "#{cat.name}/{slug}.html",
        # cat.posts/5 是 cat.paginate(page_size:5) 的简写，表示以每页5条进行分页返回 包含PostListPage的数组
        data: cat.posts/5 , # category.posts返回该分类下所有的Post的列表（PostList对象）
        template: 'list.html' # 在模板中，可以直接访问PostListPage对象的属性，详见rdoc及code
    )
end

```

Template文件支持Layout，与Post类似，模板文件也可以有一个YAML Header，
通过layout项指定它所使用的layout文件，文件路径相对于当前模板文件的路径。
不管routes.rb中data值是否有site属性,template文件中可以始终通过site名称访问到当成的Site实例，：
```erb
---
layout: base.html
---
<% content_for :page_title do %>
    <%=title%> - <%=site.name %>
<% end %>
<% content_for :page_content do %>
    <h1><%=title%></h1>
    <p>发布时间：<%=date%></p>
    <%=content%>
    <hr />
<% end %>
```

```base.html```的内容：

```erb
<html>
<head>
  <title><%=yield :page_title%></title>
</head>
<body>
  <%=yield :page_content%>
</body>
</html>
```




      
