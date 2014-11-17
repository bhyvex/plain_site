#coding:utf-8
module PlainSite;end
module PlainSite::Data
  #require 'active_support/core_ext/hash' # Silly
  #require 'active_support/hash_with_indifferent_access' # Fat
  require 'safe_yaml'
  class InvalidFrontMatterFileException<Exception;end

  class FrontMatterFile
    # YAML Front Matter File
    # Example file content:
    #   ---
    #   title: Hello,world!
    #   tags: [C,Java,Ruby,Haskell]
    #   ---
    #   File content Here!
    #
    attr_reader :path,:headers
    DELIMITER='---'

    def initialize(path)
      # The String file path
      @path=path
      # The Hash headers
      @headers={ 'path'=> path }

      @content_pos=0
      @content=nil
      File.open(path) do |f|
        line=f.readline.strip
        break if line!=DELIMITER
        header_lines=[]
        begin
          while (line=f.readline.strip)!=DELIMITER
            header_lines.push line
          end
          @headers = YAML.safe_load(header_lines.join "\n")
          unless Hash===@headers
            raise InvalidFrontMatterFileException,"Front YAML must be Hash,not #{@headers.class},in file: #{path}"
          end
          @content_pos=f.pos
        rescue YAML::SyntaxError => e
          raise  InvalidFrontMatterFileException,"YAML SyntaxError:#{e.message},in file: #{path}"
        rescue EOFError => e
          raise InvalidFrontMatterFileException,"Unclosed YAML in file: #{path}"
        end
      end
    end

    # Lazy read the file's content part(after front-matter)
    def content
      return @content unless @content.nil?
      p=@path.to_sym
      return @@cache[p] if @@cache.key? p
      File.open(path) do |f|
        f.seek @content_pos,IO::SEEK_SET
        @content=f.read.strip.freeze
      end
      @@cache[p]=@content
    end

    @@cache={}
    def self.clearCache
      @@cache={}
    end

  end
end # end PlainSite::Utils
