#coding:utf-8
module PlainSite;end
module PlainSite::Data
    require 'safe_yaml'
    require 'plain_site/data/post'
    require 'plain_site/data/post_list'

    class ConflictNameException<Exception; end

    # The Category directory class
    # File '_meta.yml' under this category dir decribes it's meta info attributes.
    # Required attributes in '_meta.yml':
    #       display_name - The String category display name
    class Category
        META_FILE='_meta.yml'
        attr_reader(
            :path, # The String full path of category directory
            :relpath, # The String path of category directory relative to site.posts_path
            :site
        )
        # path - The String category directory abspath or relative to site.posts_path,'.' means the root category
        # site - The Site belongs to
        def initialize(path,site)
            path= path[0]=='/' ? path : File.join(site.posts_path,path)
            @path=File.expand_path path
            @relpath=@path[(site.posts_path.length+1)..-1] || ''
            @site=site
            # Alias of :relpath
            alias :data_id :relpath
        end

        # whether this is the root category (aka site.posts_path)
        def root?
            @relpath==''
        end

        # Return parent category or nil if self is root
        def parent
            return @parent if @parent
            return nil if root?
            @parent=if @relpath['/']
                        Category.new File.dirname(@relpath),@site
                    else
                        Category.new '.',@site
                    end
        end

        # Return parent categories array
        def parents
            return @parents if @parents
            @parents=[]
            return @parents if root?
            cat=self
            while p=cat.parent
                @parents.push p
            end
            @parents
        end


        # Query data tree
        # path - The String|Symbol *relative* path of post or category,it can be a exact file path,or a category/slug path.
        #        Example,both 'essay/2011-11-11-live-happy.md' and 'essay/live-happy' are valid.
        #        '*' retrieve all posts under this category
        #        '**' retrieve recursively all posts under this category
        #        Category path(directory),example 'esssay',will return a new child Category .
        #        Category path ends with '/*',will return posts array under this category dir.
        #        Category path end with '/**',will return all posts array recursively.
        # Return The sub Category  when path is category path
        #        The PostList when path is category path end with '/*' or '/**'
        #        The Post when path is a post path
        def [](path)
            path=path.to_s
            if path['/']
                return path.split('/').reduce(self) {|cat,p|cat[p]}
            end

            return posts if path=='*'
            return sub_posts if path=='**'
            get_sub path or get_post path

        end
        alias :/ :[]

        # Get post by slug or filename
        # p - The String post slug or filename
        # Return the Post or nil when not found
        def get_post(p)
            if p['.'] # filename
                post_path=File.join @path,p
                if File.exists? post_path
                    return Post.new post_path,@site
                end
            end
            return posts_map[p] if posts_map.has_key? p
        end

        # The posts under this category,not contain the subcategory's posts
        # Default sort by date desc,slug asc
        # Return PostList
        def posts
            return @posts if @posts

            posts=Dir.glob(@path+'/*')
            posts.select! { |f| f[0]!='_' && (File.file? f) }

            return @posts=PostList.new([],@site) if posts.empty?

            posts.map! {|f| Post.new f,@site}

            @posts=PostList.new posts,@site
        end


        # Get all posts under category recursively
        # Return PostList
        def sub_posts
            return @sub_posts if @sub_posts
            all_posts=posts.to_a
            subs.each do |c|
                all_posts.concat c.sub_posts.to_a
            end
            @sub_posts=PostList.new all_posts,@site
        end

        # Get the sub categories
        # Return Category[]
        def subs
            return @subs if @subs
            subs=Dir.glob @path+'/*'
            subs.select! { |d| d[0]!='_' && (File.directory? d) }
            subs.map! { |d| Category.new d,@site }
            @subs=subs
        end

        # Get the sub category
        # sub_path The String path relative to current category
        # Return Category or nil
        def get_sub(sub_path)
            return nil if sub_path[0]=='_'
            sub_path=File.join @path,sub_path
            if File.directory? sub_path
                Category.new sub_path,@site
            end
        end

        # The Hash map of slug=>post
        # Return Hash
        def posts_map
            return @posts_map if @posts_map

            group=posts.group_by &:slug
            conflicts=group.reject {|k,v| v.length==1} #Filter unconflicts
            unless conflicts.empty?
                msg=(conflicts.map {|slug,v|
                    "#{slug}:\n\t"+(v.map &:path).join("\n\t")
                }).join "\n"
                raise ConflictNameException,"These posts use same slug:#{msg}"
            end

            group.merge!(group) {|k,v| v[0] }
            @posts_map=group
        end

        # The Hash map of filename=>post
        # Return Hash
        def posts_filename_map
            return @posts_filename_map if @posts_filename_map
            @posts_filename_map=Hash[posts.map {|p| [p.filename,p]}]
        end


        # Get the meta info in category path ./_meta.yml
        def meta_info
            return @meta_info if @meta_info
            meta_file=File.join(@path,META_FILE)
            if File.exists? meta_file
                @meta_info = YAML.safe_load_file meta_file
            else
                @meta_info= {}
            end
        end

        # The String category dir name,root category's name is empty string
        def name
            return @name unless @name.nil?
            @name=File.basename(data_id)
        end

        def display_name
            return @display_name unless @display_name.nil?
            @display_name=  if meta_info['display_name'].nil?
                                name.gsub(/-|_/,' ').capitalize
                            else
                                meta_info['display_name']
                            end
        end

        def to_s
            'Category:'+(@relpath.empty? ? '#root#' : @relpath)
        end
        alias :to_str :to_s

        def to_a
            parents+[self]
        end
        alias :to_ary :to_a
    end # end class Category
end # end PlainSite::Data
