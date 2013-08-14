#coding:utf-8

require 'test/unit'
require 'plain_site/tpl/lay_erb'
include PlainSite::Tpl

class LayErbTest < Test::Unit::TestCase
	FIXTURES_DIR=File.realpath (File.join File.dirname(__FILE__),'fixtures')
	def test_render
		tpl=File.join(FIXTURES_DIR,'tpl.erb')
		erb=LayErb.new tpl
		context={
			code: "some_text"
		}
		result=erb.render context
		except="<body><code class='shell'>some_text</code>Included:some_text</body>"
		assert result==except,'Tpl render with include and layout'

	end
end
