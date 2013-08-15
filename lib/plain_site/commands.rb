# coding:utf-8
module PlainSite
    module Commands
        require 'pp'
        require 'fileutils'
        require 'commander/import'
        require 'plain_site/site'

        SELF_DIR=File.dirname(__FILE__)

        def self.die(msg="\nExit now.\n")
            $stderr.puts msg
            exit 1
        end

        def self.run(action,args,opts)
            root=opts.root || Dir.pwd

            unless File.exist? root
                say_error "Site root directory does not exist:#{root}"
                say_error "Create now? [Y/n]"
                answer=$stdin.gets.strip.downcase # `agree` unable set default answer?
                answer='y' if answer.empty?
                if answer =='y'
                    FileUtils.mkdir_p root
                else
                    PlainSite.die
                end
            end
            root=File.realpath root

            self.send action,root,args,opts
        end

        def self.init(root,args,opts)
            site=Site.new root
            site.init_scaffold opts.override
            puts 'Site scaffold inited success!'
        end

        def self.build(root,args,opts)
            site=Site.new root
            site.build(dest:opts.dest,all:opts.all,includes:args)
            puts 'Posts build finish.'
        end

        def self.serve(root,args,opts)
            site=Site.new root
            site.serve(host:opts.host,port:opts.port)
        end

        def self.new_post(root,args,opts)
            site=Site.new root
            path=site.new_post args[0],args[1]
            puts "New post created in:#{path}"
        end

    end
end

