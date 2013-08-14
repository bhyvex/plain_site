#coding:utf-8
module PlainSite;end
module PlainSite::Tpl
    require 'erb'
    require 'plain_site/data/front_matter_file'
    require 'plain_site/utils'
    require 'plain_site/tpl/ext_methods'

    class LayoutNameException<Exception;end
    # Layout enhanced ERB.
    # Example:
    #   Store layout content :
    #       ---
    #       layout: base.html
    #       ---
    #       <% content_for :name %>CONTENT<%end%>
    #
    #   Retrieve layout content in base.html :
    #       <%=yield :name%>
    class LayErb
        # Huh? For short name!
        ObjectProxy=PlainSite::Utils::ObjectProxy # module include has many pitfalls
        def initialize(path)
            @path=path
            @template_file=PlainSite::Data::FrontMatterFile.new path
            @layout=@template_file.headers['layout']
        end
        # Render template with context data
        # context - The Object|Hash data
        # yield_contents - The Hash for layout yield retrieves
        def render(context,yield_contents={})
            context=ObjectProxy.new context unless ObjectProxy===context

            contents_store={}
            context.define_singleton_method(:content_for) do |name,&block|
                contents_store[name.to_sym]=echo_block &block
                nil
            end

            tpl_path=@path
            context.define_singleton_method(:include) do |file|
                file=File.join File.dirname(tpl_path),file
                new_context=context.dup
                LayErb.new(file).render new_context
            end

            begin
                result=LayErb.render_s(@template_file.content,context,yield_contents)
            rescue Exception=>e
                $stderr.puts "\nError in template:#{@path}\n"
                raise e
            end
            if @layout
                layout_path=File.join (File.dirname @path), @layout
                return  LayErb.new(layout_path).render context,contents_store
            end
            result
        end

        # Render content with context data
        # content - The String template content
        # context - The Object|Hash data
        # yield_contents - The Hash for layout yield retrieve
        def self.render_s(content,context,yield_contents={})
            context=ObjectProxy.new context unless ObjectProxy===context
            context.singleton_class.class_eval { include ExtMethods }
            erb=ERB.new content,nil,nil,'@_erbout_buf'
            result=erb.result(context.get_binding { |k| yield_contents[k.to_sym] })
            result.strip
        end
    end

end
