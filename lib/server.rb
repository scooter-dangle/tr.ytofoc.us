require_relative './guardianship.rb'
require_relative './publicist.rb'
require_relative './channel.rb'
require_relative './broadcaster.rb'
require_relative './slide_mgr.rb'
require_relative './subscription_mgr.rb'
require_relative './snitch.rb'
require 'iterable'
require 'pry'
require 'em-websocket'
#require 'net/http/server'
require 'json'

srv_opts = JSON.load IO.read 'srv_opts.json'

iterable_broadcaster = Broadcaster.new

# s = SlideMgr.new 4
# s.broadcaster = iterable_broadcaster

pub = Publicist.new
pub.broadcaster = iterable_broadcaster

arr = [*?a..?g]

Guardianship.sourcification = :defensive

iter = Guardianship.new IterableArray.new(arr.dup)

call_reset = -> { iterable_broadcaster.broadcast label: 'reset', parcel: [] }

reset = -> do
    iter = Guardianship.new IterableArray.new(arr.dup)
    iter.stage_name = 'iter'
    iter.publicist = pub
    iterable_broadcaster.clear_archives!
    iter.make_entrance
    # s.broadcast
    call_reset[]
end

# Pre-built example lambdas
ba = -> do
    iter.size
    iter.last
    iter.each { |x| iter.index x }
end

ea = -> do iter.each { |x| iter.delete x if x >= 'c' } end
cy = -> do iter.cycle(15) { |x| iter.swap! x, (iter.ward - [x]).sample } end

# Hokay let's buckle-down and get serious
reset[]

Thread.new { pry }

# TODO : Set up Subscription Manager to allow ws connections to
# subscribe/unsubscribe to broadcasters
sub_mgr = SubscriptionMgr.new
sub_mgr.add_broadcaster 'iterable_demo', iterable_broadcaster

# Need data validation before passing parcel on
routes = {
    'subscription' => ->(ws, parcel) { sub_mgr.manage ws.signature, parcel }
}
route = ->(ws, msg) { routes[msg['label']][ws, msg['parcel']] }

EventMachine.run {
    EventMachine::WebSocket.start(host: '0.0.0.0', port: srv_opts['websocket']['port'], debug: false) do |ws|
        ws.onopen { sub_mgr.add_subscriber ws.signature, ws }
        # Need exception handling for JSON.load
        ws.onmessage { |msg| route[ws, JSON.load(msg)] }
        ws.onclose { sub_mgr.remove_subscriber ws.signature }
    end
}
