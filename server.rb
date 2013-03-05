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
require 'net/http/server'
require 'json'

srv_opts = JSON.load IO.read 'srv_opts.json'

Thread.new {

    routes = {
        '/jquery.js' => 'assets/jquery.js',
        '/stylesheets/google-web-fonts.css' => 'assets/google-web-fonts.css',
        '/stylesheets/Amethysta.ttf' => 'assets/Amethysta.ttf',
        '/stylesheets/Cabin.ttf' => 'assets/Cabin.ttf',
        '/stylesheets/Stint.ttf' => 'assets/Stint.ttf',
        '/d3.js' => 'assets/d3.v2.min.js',

        '/stylesheets/screen.css' => 'simple/stylesheets/screen.css',
        '/stylesheets/print.css' => 'simple/stylesheets/print.css',

        '/logo.svg' => 'logo.svg',

        '/index.html' => 'index.html',
        '/iterable_demo.js' => 'iterable_demo.js',
    }
    routes.default = 'index.html'

    Net::HTTP::Server.run(port: srv_opts['http']['port']) do |request, stream|
        # print "Here's the request:\t"
        # print request[:uri][:path].to_str, ?\n
        # print "Preparing response\n"
        response = IO.read routes[request[:uri][:path].to_str]
        # print "Response ready\n"
        [ 200,
        # {'Content-Type' => 'text/html'},
          {},
          [response] ]
    end
}

iterable_broadcaster = Broadcaster.new

s = SlideMgr.new 19
s.broadcaster = iterable_broadcaster

pub = Publicist.new
pub.broadcaster = iterable_broadcaster

arr = [*?a..?g]

Guardianship.sourcification = :defensive

iter = Guardianship.new IterableArray.new(arr.dup)

call_reset = -> do
    # No need to use JSON.dump here since that's what
    # Broadcaster#formatter is for
    iterable_broadcaster.broadcast label: 'reset', parcel: []
end

reset = -> do
    iter = Guardianship.new IterableArray.new(arr.dup)

    iter.stage_name = 'iter'

    iter.publicist = pub

    iterable_broadcaster.clear_archives!

    iter.make_entrance
    s.broadcast

    call_reset[]
end

# Pre-built example lambdas
ba = -> do
    iter.size
    iter.last
    iter.each { |x| iter.index x }
end

ea = -> do
    iter.each { |x| iter.delete x if x >= 'c' }
end

cy = -> do
    iter.cycle(15) { |x| iter.swap! x, (iter.ward - [x]).sample }
end

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
