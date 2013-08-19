
#coding:utf-8
module PlainSite
    require 'socket'
    module SocketPatch
        class ::TCPSocket
            def peeraddr(*args,&block)
                # Fixed:http://www.w-yong.com/docs/webrick_lan.html
                args.push :numeric unless args.include? :numeric
                super *args,&block
            end
        end
    end
end

