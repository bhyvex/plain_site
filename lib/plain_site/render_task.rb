#coding:utf-8

module PlainSite
    require 'fileutils'
    require 'plain_site/data/post_list'
    require 'plain_site/data/post_list_page'
    require 'plain_site/data/post'
    require 'plain_site/tpl/lay_erb'
    require 'plain_site/utils'

    class BadUrlPatternException<Exception;end
    class RenderTask
        Post=Data::Post
        PostList=Data::PostList
        PostListPage=Data::PostListPage
        attr_reader :site
        # site - The Site
        def initialize(site)
            @site=site
            @tasks=[]
        end

        # Options:
        # url_pattern - The String with var replacement pattern "{property.property}"
        #           "{property.property}" is the data Hash key path.
        #           Example:
        #           "/article/{date.year}/{name}.html" will render url
        #           "/article/2011/hello-world.html"
        #                   with example data "posts/2011-09-09-hello-world.md"
        # data - The Array|PostList|Object|String data to render
        #        In String case,it reprents the post.data_id or category.data_id.
        #        Example: 'essay/*' same as $site.db['essay/*']
        #        If data is Array or PostList,will generate each item with template,
        #        else only generate one page
        # template - The String template relative path in '_site/templates'
        # build_anyway - The Boolean value to indicate
        #                   this route rule will build anyway even if no post updates
        def route(opts)

            url_pattern=opts[:url_pattern]
            items=opts[:data]
            template=opts[:template]
            build_anyway=opts[:build_anyway]

            if String===items
                items=@site.db[items]
                raise Exception,"Data not found:#{opts[:data]}!" if items.nil?
            end
            items=[items] unless Data::PostList===items || Array===items

            tasks= items.map do |item|
                url=RenderTask.sub_url url_pattern,item
                url[0]=''  if url[0]=='/'
                id =if item.respond_to? :data_id
                        item.data_id
                    else
                        item.object_id
                    end
                { id: id, url: url, item: item,
                    template:File.join(@site.templates_path,template),
                    build_anyway:build_anyway }
            end
            @tasks.concat tasks
        end

        # The Hash of data_id=>url or object_id=>url
        def id2url_map
            return @id2url_map if @id2url_map
            @id2url_map=@tasks.group_by {|a| a[:id]}
            @id2url_map.merge!(@id2url_map) do |k,v|
                if v.length>1
                    urls=(v.map {|a|a[:url]}).join "\n\t"
                    $stderr.puts "Object[#{k}] has more than one url:"
                    $stderr.puts "\t#{urls}"
                end
                v[0][:url]
            end
            @id2url_map
        end

        # Render  pages
        # partials - The Hash of updated and deleted posts and templates
        # updated items includes new and modified two cases
        # Structure:
        # {
        #     updated_posts:[],
        #     updated_templates:[],
        #     deleted_posts:[]
        # }
        def render(partials=nil)
            if partials.nil?
                @tasks.each do |t|
                    render_task t
                end
                return
            end

            build_tasks,other_tasks=@tasks.partition {|t|!!t[:build_anyway]}

            if tpls=partials[:updated_templates]
                a,other_tasks=other_tasks.partition {|t|tpls.include? t[:template] }
                build_tasks.concat a
            end
            if posts=partials[:updated_posts]
                a,other_tasks=other_tasks.partition do |t|
                    item=t[:item]
                    next posts.include? item.path if Post===item
                    next posts.any? {|p|item.include? p} if PostList===item || PostListPage===item
                end
                build_tasks.concat a
            end

            if posts=partials[:deleted_posts]
                # re generate all post list page
                a,other_tasks=other_tasks.partition {|t|PostList===t[:item] || PostListPage===t[:item]}
                build_tasks.concat a
            end
            build_tasks.each do |t|
                render_task t
            end
        end

        # Render single url corresponding task
        # url - The String url path one can be used in browser,such as
        #           '/posts','/posts/','/posts/index.html' are both valid
        # Returns the String page content
        def render_url(url)
            url=url.dup
            url[0]=''  if url[0]=='/'
            url=url+'index.html' if url.end_with? '/'
            url=url+'/index.html' if site.url.start_with? url
            t = @tasks.detect {|t|t[:url]==url}
            if t
                return render_task t,false
            end
        end

        def render_task(t,write_file=true)
            item=t[:item]
            url=t[:url]
            template=t[:template]

            item=Utils::ObjectProxy.new item,{site:@site} # Keep site is always accessable
            erb=Tpl::LayErb.new template
            result=erb.render item

            return result unless write_file
            output_path=File.join(@site.dest,url)
            dir=File.dirname output_path
            FileUtils.mkdir_p dir unless File.exist? dir
            File.open(output_path,'wb') do |f|
                f.write result
            end
        end
        private :render_task

        # Render url_pattern with context data
        # url_pattern - The String url pattern.
        # context - The Object context
        def self.sub_url(url_pattern,context)
            url_pattern.gsub(/\{([^{}\/]+)\}/) do
                m=$1
                key_path=m.strip.split '.'
                key_path.reduce(context) do |o,key|
                    v = if o.respond_to? key
                            o.send key
                        elsif (o.respond_to? :[])
                            o[key] || o[key.to_sym]
                        end
                    next v if v
                    raise BadUrlPatternException,"Unresolved property `#{m}` in url pattern [#{url_pattern}]!"
                end
            end
        end

    end

end
