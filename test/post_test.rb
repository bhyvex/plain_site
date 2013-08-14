#coding:utf-8

require 'test/unit'
require 'fileutils'

require 'plain_site/data/post'
require 'plain_site/data/category'
require 'plain_site/site'

include PlainSite::Data
include PlainSite

class PostTest < Test::Unit::TestCase
    FIXTURES_DIR=File.realpath (File.join File.dirname(__FILE__),'fixtures')
    def setup
        @site_root=File.join FIXTURES_DIR,'test-site'
        FileUtils.mkdir_p @site_root
        @site=Site.new @site_root
        @site.init_scaffold true
    end
    def teardown
        FileUtils.rm_rf @site_root
    end

    def test_content
        content="<p>Hello!Tags:Demo,Example<span class=\"highlight\"><span class=\"nb\">puts</span></span></p>"
        path='2012-06-12-test.md'
        FileUtils.copy_file File.join(FIXTURES_DIR,path),File.join(@site.posts_path,path)

        f=@site.db['test']
        #assert f.draft,'Post shoud be a draft'
        #assert f.draft?,'Post shoud be a draft'
        assert f.date.year==2012,'Post year 2012'
        assert f.date.month==6,'Post month 6'
        assert f.date.day==12,'Post day 12'
        assert f.slug=='test','Post slug test'
        assert f.tags==['Demo','Example'],'Post tags read'

        assert f.relpath==path,'Post relpath'
        assert f.data_id=='test','Post data_id'

        assert f.content_type=='md','Post should be markdown'

        assert f.content==content,'Post content render not correct'

        assert Category===f.category,'Post.category'

    end
end
