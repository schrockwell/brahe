Bundler.require

Opal::Processor.source_map_enabled = true

require 'open-uri'
require 'json'

require_relative '../lib/satellite_cache'
require_relative '../lib/satellite_calcs'

require_relative 'app'