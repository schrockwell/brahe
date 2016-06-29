require_relative 'app/init'

Opal::Processor.source_map_enabled = true

$opal = Opal::Server.new {|s|
  s.append_path './app'
  s.main = 'opal'
  s.debug = true
}

map $opal.source_maps.prefix do
  run $opal.source_maps
end rescue nil

map '/assets' do
  run $opal.sprockets
end

run Sinatra::Application