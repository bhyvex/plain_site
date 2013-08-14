#coding:utf-8

require 'test/unit'
require 'fileutils'
require 'set'
require 'plain_site/site'
include PlainSite

class SiteTest < Test::Unit::TestCase
    FIXTURES_DIR=File.realpath (File.join File.dirname(__FILE__),'fixtures')
    def setup
        @site_root=Dir.mktmpdir 'test-site-'
    end
    def teardown
        FileUtils.rm_rf @site_root
    end

    def test_diff_build
        site_url='file://'+@site_root+'/'
        site=Site.new @site_root
        site.init_scaffold true
        site.url=site_url
        assert site.diff_files.nil? ,"Should diff_files be nil"

        to_del_post=site.new_post 'essay/git-test1','Git Test 1'
        to_mod_post=site.new_post 'essay/git-test3','Git Test 3'

        `(cd #{@site_root};
        git init;
        git add .;
        git commit -m Init;)`

        FileUtils.rm to_del_post
        File.open(to_mod_post,'wb') {|f| f.write "---\ntitle: Modified\n---\n Modified!"}
        new_post=site.new_post 'essay/git-untracked','Git Test Untracked'

        added_template=File.join site.templates_path,'test.html'
        File.open(added_template,'wb') {|f| f.write 'TEST Template'}
        `(cd #{@site_root};
        git add #{added_template});`

        files=site.diff_files

        assert [to_mod_post,new_post].to_set <= files[:updated_posts].to_set ,"Should include new and modified posts"
        assert (files[:deleted_posts].include? to_del_post), "Should include deleted post"

        assert (files[:updated_templates].include? added_template), "Should include added template"


        site2=Site.new @site_root
        site2.url=site_url
        site2.build

    end

    def test_build
        site=Site.new @site_root
        site.init_scaffold true
        site.url='file://'+@site_root+'/'


        site.db.subs.each do |cat|
            20.times do |i|
                name="2014-#{rand 1..12}-#{rand 1..28 }-hello-post#{i}.md"
                path=File.join cat.path,name
                File.open(path,'wb') do |f|
                    s= <<-CONTENT
---
title: Hello,post#{i}
---

**Content here!**

Category: <a href="<%=URI.join site.url,"#{cat.name}"%>">#{cat.display_name}</a>


<highlight python>
def hello(name):
    print "Hello,%s" % name

if __name__=='__main__':
    hello("World!")
</highlight>
CONTENT
                    f.write s
                end
            end
        end

        #site.build(dest:dest)
        site.build
        #puts "\n#{@site_root}\n"
        #site.serve
    end
end
