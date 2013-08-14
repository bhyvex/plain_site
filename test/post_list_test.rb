#coding:utf-8

require 'test/unit'
require 'grit'
require 'fileutils'
require 'plain_site/site'
include PlainSite

class PostListTest < Test::Unit::TestCase
    def setup
        @site_root=Dir.mktmpdir 'test-site-'
    end
    def teardown
        FileUtils.rm_rf @site_root
    end

    def test_list
        site=Site.new @site_root
        site.init_scaffold true
        posts_path=[]

        site.db.subs.each do |cat|
            12.times do |i|
                name="2014-#{i+1}-22-hello-#{cat.name}-#{i+1}.md"
                path=File.join cat.path,name
                posts_path.push path
                File.open(path,'wb') do |f|
                    f.write "---\ntitle: Hello,#{cat.name},#{i+1}\n---\n XXX"
                end
            end
        end

        pages=site.db / :essay / '*' / 5

        assert pages[0].prev_page.nil?,"Should first page's prev_page be nil"
        assert pages[0].posts.length==5,"Page size should be 5"
        pages[0].posts.each_with_index do |p,i|
            d=Date.new 2014,12-i,22
            assert p.date == d,"Date should be #{d}"
        end


        all_posts=site.db['**']
        one_page=(all_posts/100).first

        posts_path.each do |p|
            assert (all_posts.include? p),"Should PostList include post:#{p}"
            assert (one_page.include? p),"Should PostListPage include post:#{p}"
        end


    end
end
