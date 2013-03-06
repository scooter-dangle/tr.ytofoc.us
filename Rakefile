$OPTS_FILE = 'srv_opts.json'

desc "Create '#{$OPTS_FILE}' with development settings if in doesn't yet exist"
file $OPTS_FILE do |t|
    unless File.exists? t.name
        puts "Creating #{t.name}"
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
        IO.write t.name, dev_opts
    end
end

desc "Update websocket host/port in 'iterable_demo.coffee' from '#{$OPTS_FILE}'"
file 'iterable_demo.coffee' => $OPTS_FILE do |t|
    puts "Checking WebSocket url in #{t.name}"
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
    iterable_demo = IO.read t.name
    m = reg.match iterable_demo
    unless m and m['host'] == ws_opts['host'] and m['port'] == ws_opts['port'].to_s
        iterable_demo.gsub! %r{#{m['host']}:#{m['port']}}, "#{ws_opts['host']}:#{ws_opts['port']}"
        puts "Updating #{t.name}"
        IO.write t.name, iterable_demo
    end
end

rule '.svg' => '.svg.haml' do |t|
    puts "Compiling #{t.source} => #{t.name}"
    sh "haml #{t.source} #{t.name}"
end

rule '.html' => '.html.haml' do |t|
    puts "Compiling #{t.source} => #{t.name}"
    sh "haml --format html5 #{t.source} #{t.name}"
end

desc 'Compile haml files'
FileList['*.*.haml'].ext.each do |x|
    task haml: x
end
file 'index.html' => $OPTS_FILE

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

rule(%r{^\w*/stylesheets/\w*\.css$} => (->(tn) { "#{tn.pathmap '%1d'}/sass/#{tn.pathmap '%n'}.sass" })) do |t|
    sh "cd #{t.name.pathmap '%1d'} && compass comp sass/#{t.source.pathmap '%f'}"
end

desc 'Compile sass stylesheets'
FileList['*/sass/*.sass'].each do |x|
    task sass: x.pathmap('%1d/stylesheets/%n.css')
end

desc 'Compile all files'
multitask comp: [:haml, :coffee, :sass]

desc 'Start server'
task :server do
    puts "Note: if you're using ports with elevated permissions, you may need\nto run `sudo ruby server.rb` or `rvmsudo ruby server.rb`"
    sh 'ruby server.rb'
end

task default: [:comp, :server]
