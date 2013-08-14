#coding:utf-8

module PlainSite;end
module PlainSite::Tpl
	require 'erb'
	module ExtMethods
		require 'uri'
		include ERB::Util
		def echo_block(&block)
			old=@_erbout_buf
			@_erbout_buf=""
			block.call
			block_content=@_erbout_buf.strip
			@_erbout_buf=old
			block_content
		end
		def shell(code)
			code=html_escape code
			"<code class='shell'>#{code}</code>"
		end

	end
end
