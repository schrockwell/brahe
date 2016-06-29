require 'opal'
require 'browser/interval'
require 'jquery'
require 'opal-jquery'
require 'opal-activesupport'
require 'json'
require 'react'
require 'react-dom'
require 'reactrb'

Document.ready? do
  React.render(                                            
    React.create_element(
      SatelliteTable, :poll_interval => 1, :url => '/current'
    ), 
    Element['#sat-table']
  )
end

class SatelliteTable
  include React::Component

  param :poll_interval, :type => Fixnum
  param :url, :type => String

  define_state :sats => []

  before_mount do
    @fetcher = every(params.poll_interval) do
      HTTP.get(params.url) do |response|
        if response.ok?
          state.sats! response.json['satellites']
        else
          puts "failed with status #{response.status_code}"
        end
      end
    end
  end
    
  after_mount do
    @fetcher.start
  end
  
  before_unmount do
    @fetcher.stop
  end

  def render
    table :class => 'table' do
      thead do
        tr do
          th { 'Name' }
          th { 'Lat' }
          th { 'Long' }
          th { 'Alt (km)' }
        end
      end
      tbody do
        state.sats.each do |sat|
          tr :key => sat['id'] do
            td { sat['name'] }
            td { '%02.6f' % sat['lat'] }
            td { '%03.6f' % sat['lng'] }
            td { sat['alt_km'].to_s }
          end
        end
      end
    end
  end
end