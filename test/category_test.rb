#coding:utf-8

require 'test/unit'
require 'fileutils'
require 'plain_site/data/post'
require 'plain_site/data/post_list'
require 'plain_site/data/category'
require 'plain_site/site'
include PlainSite::Data
include PlainSite

class CategoryTest < Test::Unit::TestCase
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

    def test_category
        FileUtils.cp_r File.join(FIXTURES_DIR,'category-demo'),@site.posts_path

        cat=@site.db / :'category-demo'

        assert cat,'Read category demo'
        assert cat.root? == false ,'Category should not be root'
        assert @site.db.root? ,'site.db is root'
        assert cat.display_name=='DemoDemo','Category display name'

        post1=cat / :post1
        post2=cat / :post2
        assert post1.data_id=='category-demo/post1','Read post1'
        assert post2.category.data_id==cat.data_id,'Read post2'

        assert PostList===cat['*'],'Read post list'

        subs=cat.subs
        assert subs.length==2,'Sub category should be 2'

        sub1=cat['sub-category1']
        assert sub1.display_name=='Sub category1','Sub category display name'

        sub1=cat / 'sub-category1'
        assert sub1.display_name=='Sub category1','Sub category display name'

    end
end
