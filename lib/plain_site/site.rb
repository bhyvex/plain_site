#coding:utf-8
module PlainSite
    require 'grit'
    require 'uri'
    require 'fileutils'
    require 'webrick'
    require 'plain_site/data/category'
    require 'plain_site/data/post'
    require 'plain_site/render_task'
    require 'plain_site/utils'
    require 'listen'

    class Site
        SELF_DIR=File.realpath File.dirname(__FILE__)
        SCAFFOLD_DIR=File.join(SELF_DIR,'_stuffs/scaffold')
        attr_reader(
            :root,
            :dest, # Alter build destination directory,default same as root
            :posts_path, # The String posts path
            :templates_path # The String templates path
        )
        attr_writer :url,:name

        # Params
        # root - The String root path of site,must be an exists path
        def initialize(root)
            @root= File.realpath root
            @dest= @root
            @app_path=File.join(@root,'_site')
            @posts_path=File.join(@app_path,'posts')
            @routes_rb=File.join(@app_path,'routes.rb')
            @templates_path=File.join(@app_path,'templates')
            @assets_path=File.join(@app_path,'assets')
            @config_file= File.join(@app_path,'config.yml')
        end

        # Reload,clean cached instance variables read from file
        def reload
            @config=nil
            @name=nil
            @db=nil
            @render_task=nil
        end

        # The Hash config defined if config.yml
        def config
            return @config if @config
            @config = (File.exists? @config_file) ? (YAML.safe_load_file @config_file) : {}
        end

        # The String site root url,example:http://jex.im,define in config.yml: config['url']
        def url
            @url = @url || config['url'] || ''
        end

        def name
            @name = @name || config['name'] || ''
        end

        # Return the Category object represents _site/posts
        def db
            return @db if @db
            @db=Data::Category.new @posts_path,self
            # cat=Data::Category.new @posts_path,self
            # self.define_singleton_method(__method__) {cat}
            # cat
        end

        # Copy _site/assets to root
        def copy_assets
            Utils.merge_folder @assets_path,@dest
        end

        # Init site structure
        def init_scaffold(override=false)
            Utils.merge_folder SCAFFOLD_DIR,@root,override
        end

        # Create a new post file
        def new_post(p,title)
            ext=File.extname(p)[1..-1]
            if ! (Data::Post.supported_ext_names.include? ext)
                ext=Data::Post.supported_ext_names[0]
            end

            name=File.basename p,File.extname(p)
            name="#{Date.today}-#{name}" unless Data::Post::DATE_NAME_RE=~name
            name= "#{name}.#{ext}"

            if p['/']
                path=File.join @posts_path,(File.dirname p)
                FileUtils.mkdir_p  path
            else
                path=@posts_path
            end
            path="#{path}/#{name}"
            File.open(path,'wb') do |f|
                f.write "---\ntitle: #{title}\n---\n\n#{title}"
            end
            path
        end

        def render_task
            return @render_task if @render_task
            @render_task=RenderTask.new self

            old_site=$site
            $site=self
            load @routes_rb
            $site=old_site
            @render_task
        end

        # Build static pages
        # all - The Boolean value to force build all posts.Default only build updated posts.
        # dest - The String path of destination directory
        def build(opts={})
            @dest= opts[:dest] if opts[:dest]
            files=diff_files
            if opts[:all] || files.nil?
                render_task.render
            else
                render_task.render(files)
            end
            create_pygments_css
            copy_assets
        end

        # Get diff_files
        # since - The String of absolute revision or relative negative number,default to last commit
        # updated items includes new and modified two cases
        #
        # Return Hash
        # Structure:
        # {
        #     updated_posts:[],
        #     updated_templates:[],
        #     deleted_posts:[]
        # }
        def diff_files(since=nil)
            begin
                repo=Grit::Repo.new @root
            rescue Grit::InvalidGitRepositoryError
                $stderr.puts "\nSite root is not a valid git repository:#{@root}\n"
                return nil
            end
            files=%w(untracked added changed).map {|m|(repo.status.send m).keys}.flatten
            files=files.map {|f|File.join @root,f}.group_by do |f|
                if f.start_with? @posts_path+'/'
                    :updated_posts
                elsif f.start_with? @templates_path+'/'
                    :updated_templates
                end
            end
            files.delete nil

            deleted_posts=repo.status.deleted.keys.map {|f|File.join @root,f}
            deleted_posts.select! do |f|
                f.start_with? @posts_path
            end
            files[:deleted_posts]=deleted_posts
            files
        end

        def serve_static(server,static_file,req,res)
            handler=WEBrick::HTTPServlet::DefaultFileHandler.new server,static_file
            handler.do_GET req,res
        end
        private :serve_static

        # Run a preview server on 0.0.0.0:1990
        def serve(opts={})
            host=opts[:host] || '127.0.0.1'
            port=opts[:port] || '1990'
            self.url= "http://#{host}:#{port}"
            create_pygments_css
            Listen.to(@app_path) do |m, a, d|
                self.reload
            end

            server = WEBrick::HTTPServer.new(Port:port,BindAddress:host)
            server.mount_proc '/' do |req,res|
                url= req.path_info
                url= '/index.html' if url=='/'
                static_file=File.join @assets_path,url
                if (File.exists? static_file) && !(File.directory? static_file)
                    serve_static server,static_file,req,res
                    next
                end
                result=render_task.render_url url
                if result
                    res['Content-Type'] = 'text/html'
                    res.body=result
                    next
                end
                static_file=File.join @dest,url
                if File.exists? static_file
                    serve_static server,static_file,req,res
                    next
                end
                res.status=404
                res.body='404 Not Found:'+url
            end
            t = Thread.new { server.start }
            trap('INT') { server.shutdown }
            puts "\nServer running on http://#{host}:#{port}/\n"
            t.join
        end

        # Config route specified data with ordered template and url path.
        # See: RenderTask#route
        def route(opt)
            @render_task.route(opt)
        end

        # Get the url for object
        # obj - The Post|PageListPage|Category|String|Object some thing
        # Return the String url prefix with site root url(site.url)
        def url_for(obj)
            id =if String===obj
                    obj
                elsif obj.respond_to? :data_id
                    obj.data_id
                else
                    obj.object_id
                end
            (URI.join url,@render_task.id2url_map[id] || '').to_s
        end

        def create_pygments_css
            return unless config['code_highlight'] && config['code_highlight']['engine']=='pygments'
            cls='.highlight'
            css_path=config['code_highlight']['pygments_css'] || '/css/pygments.css'
            css_path=File.join @assets_path,css_path
            style=config['code_highlight']['pygments_style'] || 'native'
            FileUtils.mkdir_p File.dirname(css_path)
            css_content=Pygments.css(cls,style:style)
            File.open(css_path,'wb') do |f|
                f.write css_content
            end
        end

    end
end
