$OPTS_FILE = 'srv_opts.json'

rule '.svg' => '.svg.haml' do |t|
    puts "Compiling #{t.source} => #{t.name}"
    sh "haml #{t.source} #{t.name}"
end

rule '.html' => '.html.haml' do |t|
    puts "Compiling #{t.source} => #{t.name}"
    sh "haml --format html5 #{t.source} #{t.name}"
end

desc "Create '#{$OPTS_FILE}' with development settings if in doesn't yet exist"
task :opts_init do
    unless File.exists? $OPTS_FILE
        dev_opts = <<EOS
{
    "http": {
        "port": 3030
    },
    "websocket": {
        "host": "localhost",
        "port": 8080
    },
    // set "js_assets" to "remote" to load jQuery, d3.js, et al. from the Internets
    // set "js_assets" to "local" to load them based on routes provided in the first
    // half of server.rb (This is useful if you're developing on an non-networked
    // device, but make sure you actually *have* them locally.) This option is used
    // when index.html.haml is compiled to index.html by rake
    "js_assets": "remote"
}
EOS
        IO.write $OPTS_FILE, dev_opts
    end
end

desc "Update websocket host/port in 'iterable_demo.coffee' from '#{$OPTS_FILE}'"
task opts_update: :opts_init do
    require 'json'
    ws_opts = (JSON.load IO.read $OPTS_FILE)['websocket']
    reg = %r{
        (?<before>
            (phone_home\s*=\s*.*->\n)
            (.*\n)*
            (\s*\S*\s*=\s*new\s*WebSocket\s*('|")ws://)
        ){0}
        (?<domain> [[:word:]]*([#-.@][[:word:]]*)*){0}
        (?<host> \g<domain>){0}
        (?<port> \d*){0}

        \g<before>\g<host>:\g<port>
    }ix
    iterable = IO.read 'iterable_demo.coffee'
    m = reg.match iterable
    unless m and m['host'] == ws_opts['host'] and m['port'] == ws_opts['port'].to_s
        iterable.gsub! %r{#{m['host']}:#{m['port']}}, "#{ws_opts['host']}:#{ws_opts['port']}"
        puts 'Updating "iterable_demo.coffee"'
        IO.write 'iterable_demo.coffee', iterable
    end
end

desc 'Compile haml files'
FileList['*.*.haml'].ext.each do |x|
    multitask haml: x
end

# Learnt of rake's rules (and copied some code) from
# github.com/ngauthier/coffeescript-ruby-pipeline
rule '.js' => '.coffee' do |t|
    puts "Compiling #{t.source} => #{t.name}"
    sh "coffee -c #{t.source}"
end

desc 'Compile coffeescript files'
FileList['*.coffee'].ext('js').each do |x|
    task coffee: x
end

task :sass do
    sh "compass comp simple"
end

desc 'Compile all files'
multitask comp: [:haml, :coffee, :sass]

desc 'Start server'
task :server do
    puts "Note: if you're using ports with elevated permissions, you may need\nto run `sudo ruby server.rb` or `rvmsudo ruby server.rb`"
    sh 'ruby server.rb'
end

task default: [:opts_update, :comp, :server] do
end
