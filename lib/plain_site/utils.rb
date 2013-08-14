#coding:utf-8
module PlainSite;end
module PlainSite::Utils
    require 'fileutils'

    class ObjectProxy
        def initialize(*objects)
            @objects=objects
        end

        def <<(*objects)
            @objects.concat objects
        end

        def dup
            ObjectProxy.new *@objects
        end

        def clone
            ObjectProxy.new self
        end

        def respond_to?(name)
            return true if @objects.any? do |o|
                o.respond_to? name || ((o.respond_to? :key?) && ((o.key? name) || (o.key? name.to_s)))
            end
            super
        end

        def method_missing(name,*args,&block)
            o=@objects.detect {|o|o.respond_to? name}
            if o
                define_singleton_method(name) do |*a,&b|
                    o.send name,*a,&b
                end
                return o.send name,*args,&block
            end
            if args.empty? && block.nil?
                o=@objects.detect {|o|(o.respond_to? :key?) && ((o.key? name) || (o.key? name.to_s))}
                if o
                    define_singleton_method(name) do
                        o[name] || o[name.to_s]
                    end
                    return o[name] || o[name.to_s]
                end
            end
            super
        end

        def get_binding
            binding
        end
    end

    # Copy src folder's contents to dest folder recursively merge
    # src - The String source directory
    # dest - The String destination directory
    # override - The Boolean value to indicate whether override exist file,default is false
    def self.merge_folder(src,dest,override=false)
        src=File.realpath src
        files=Dir.glob src+'/**/*',File::FNM_DOTMATCH
        prefix_len=src.length+1
        files.each do |src_path|
            rel_path=src_path[prefix_len..-1]
            dest_path=File.join(dest,rel_path)
            if File.directory? src_path
                FileUtils.mkdir_p dest_path
            else
                if override || !(File.exist? dest_path)
                    FileUtils.copy_file src_path,dest_path
                end
            end
        end

    end

    # List a directory as a hash tree
    #   dir - The String directory path
    #   level - The Integer deepth level,zero means unlimit level,default unlimit
    # Return The Hash tree map
    def self.dir_tree(dir,level=0)
        ls=Dir.glob dir+'/*'
        return ls.reject &(File.method :directory?) if level==1
        self_files=[]
        ls.map! do |f|
            if File.directory? f
                next [(File.basename f).to_sym,dir_tree(f,level-1)]
            else
                self_files.push f
                next ['.'.to_sym,self_files]
            end
        end
        Hash[ls]
    end
end


