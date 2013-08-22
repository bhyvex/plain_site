#coding:utf-8
module PlainSite;end
module PlainSite::Data
    require 'pygments'
    require 'maruku'
    require 'securerandom'
    require 'plain_site/data/front_matter_file'
    require 'plain_site/tpl/lay_erb'

    class Post
        attr_reader(
            :date, # The Date of post
            :slug, # The String slug of post,default is it's filename without date and dot-extname
            :path, # The String post file path
            :relpath, # The String path relative to site.posts_path
            :data_id, # The String data id,format:'category/sub-category/slug'
            :category_path, # The String category path
            :filename, # The String filename
            :site
        )

        attr_accessor( #These properties are inited by others
            :prev_post, # The Post previous,set by PostList
            :next_post, # The Post next,set by PostList
        )

        DATE_NAME_RE=/^(\d{4})-(\d{1,2})-(\d{1,2})-(.+)$/
        HIGHLIGHT_RE=/<highlight\s+([\w+-]+)(\s+linenos(=\d+)?)?\s*>(.+?)<\/highlight>/m

        # Init a post
        # path - The String file abs path or relative to site.posts_path,at present,only support '.html' and '.md' extname.
        # site - The Site this post belongs to
        def initialize(path,site)
            path= path[0]=='/' ? path : File.join(site.posts_path,path)
            @site=site
            @path=File.expand_path path
            @relpath=@path[(site.posts_path.length+1)..-1]

            @filename=File.basename @path
            @extname=File.extname @filename
            if DATE_NAME_RE =~ @filename
                @date=Date.new $1.to_i,$2.to_i,$3.to_i
                @slug=File.basename $4,@extname
            else
                @date=Date.today
                @slug=File.basename @filename,@extname
            end
            @category_path=File.dirname(@relpath)
            if @category_path=='.'
                @category_path=''
                @data_id=@slug
            else
                @data_id=File.join @category_path,@slug
            end

        end

        # The Category this post belongs to
        def category
            return @category if @category
            require 'plain_site/data/category'
            @category=Category.new @category_path,@site
        end

        # The String content type of post,default is it's extname without dot
        def content_type
            return @content_type if @content_type
            @content_type=post_file.headers['content_type']
            @content_type=@extname[1..-1] if @content_type.nil?
            @content_type
        end

        # The Boolean value indicates if this post is a draft,default is false,alias is `draft?`
        # def draft
        #     return @draft unless @draft.nil?
        #     @draft=!!post_file.headers['draft']
        # end
        # alias :draft? :draft

        # def deleted
        #     return @deleted unless @deleted.nil?
        #     @deleted=!!post_file.headers['deleted']
        # end
        # alias :deleted? :deleted

        # Private
        def post_file
            return @post_file if @post_file
            @post_file=FrontMatterFile.new @path
        end
        private :post_file

        # Post file raw content
        def raw_content
            post_file.content
        end

        # Content html
        # Render highlight code first
        # Example:
        #   It's html tag syntax,language is required!
        #   <highlight ruby>puts 'Hello'</highlight>
        #   With line numbers
        #   <highlight ruby linenos>puts 'Hello'</highlight>
        #   Set line number start from 10
        #   <highlight ruby linenos=10>puts 'Hello'</highlight>
        #
        # Highlight options:
        #   linenos - If provide,output will contains line number
        #   linenos=Int - Line number start from,default is 1
        #
        # If no new line in code,the output will be inline nowrap style and no linenos.
        #
        # Then render erb template,context is self,you can access self and self.site methods
        #
        # Return the String html content
        def content
            return @content if @content

            post_content=raw_content.dup
            # stash highlight code
            highlights={}
            post_content.gsub! HIGHLIGHT_RE  do
                placeholder='HIGHLIGHT-'+SecureRandom.uuid+'-ENDHIGHLIGHT'
                highlights[placeholder]={
                    lexer:$1,
                    linenos: $2 ? 'table' : false ,
                    linenostart: $3 ? $3[1..-1].to_i : 1,
                    code: $4.strip,
                    nowrap:$4["\n"].nil?
                }
                placeholder
            end
            # Then render erb template if needed
            post_content=PlainSite::Tpl::LayErb.render_s post_content,self if post_content['<%']
            post_content=self.class.content_to_html post_content,content_type

            #put back code
            highlights.each do |k,v|
                code=Pygments.highlight v[:code],lexer:v[:lexer],options:{
                        linenos:v[:linenos],
                        linenostart:v[:linenostart],
                        nowrap:v[:nowrap],
                        startinline: v[:lexer] == 'php'
                }
                code="<span class=\"highlight\">#{code}</span>" if v[:nowrap]
                post_content[k]=code # String#sub method has a hole of back reference
            end
            post_content
        end

        # The String url of this post in site
        def url
            @site.url_for @data_id
        end

        # You can use method call to access post file front-matter data
        def respond_to?(name)
            return true if post_file.headers.key? name.to_s
            super
        end

        def method_missing(name,*args,&block)
            if args.length==0 && block.nil? &&  post_file.headers.key?(name.to_s)
                return post_file.headers[name.to_s]
            end
            super
        end

        # Keep track of all instances
        # @@instances={}
        # Keep same path return same instance but reinit the writable attributes
        # def self.new(path,site)
        #   path= path[0]=='/' ? path : File.join(site.posts_path,path)
        #   if @instances.has_key? path
        #       @instances[path].dup
        #   else
        #       post=super
        #       @instances[path]=post
        #   end
        # end

        def self.content_to_html(content,content_type)
            if content_type=='md'
                content=Maruku.new(content).to_html
            end
            content
        end

        def self.supported_ext_names
            ['md','html']
        end

    end # class Post
end # module PlainSite::Data
