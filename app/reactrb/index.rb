require 'opal'
require 'browser/interval'
require 'opal-jquery'
require 'opal-activesupport'
require 'json'
require 'react'
require 'react-dom'
require 'reactrb'

Document.ready? do
  React.render(                                            
    React.create_element(
      UpdatingSatelliteTable, 
        :poll_interval => 0.5,
        :coords => [41.843478, -69.979048],
        :sat_ids => ['07530', '40074', '24278', '40903', '40906', '40910', '27607', '40654', '40967', '25544']
    ),
    Element['#sat-table']
  )

  React.render(                                            
    React.create_element(
      UpdatingPassesTable, 
        :coords => [41.843478, -69.979048],
        :sat_ids => ['07530', '40074', '24278', '40903', '40906', '40910', '27607', '40654', '40967', '25544']
    ),
    Element['#passes-table']
  )
end

class SatelliteTable < React::Component::Base
  param :sats, :type => [Hash], :default => []

  def render
    table :class => 'table' do
      thead do
        tr do
          th { 'Name' }
          th { 'Lat' }
          th { 'Long' }
          th { 'Az' }
          th { 'El' }
          th { 'Alt (km)' }
        end
      end
      tbody do
        if params.sats.count == 0
          tr { td(:colspan => 6) { 'Loading...' } }
        end

        params.sats.each do |sat|
          look = sat['look']

          if look && look['el'] > 5
            tr_class = 'success'
          elsif look && look['el'] > 0
            tr_class = 'warning'
          else
            tr_class = nil
          end

          tr :key => sat['id'], :class => tr_class do
            td { sat['name'] }
            td { '%02.6f' % sat['lat'] }
            td { '%03.6f' % sat['lng'] }
            td { look['az'].to_s if look != nil }
            td { look['el'].to_s if look != nil }
            td { sat['alt_km'].to_s }
          end
        end
      end
    end
  end
end

class PassesTable < React::Component::Base
  param :passes, :type => [Hash], :default => []

  define_state :now => Time.now

  before_mount do
    @updater = every(1) do
      state.now! Time.now
    end
  end

  after_mount do
    @updater.start
    @updater.call
  end

  before_unmount do
    @updater.stop
  end

  def render
    table(:class => 'table table-hover') do
      thead do
        tr do
          th { 'Sat' }
          th { 'AOS' }
          th { 'Max' }
          th { 'LOS'}
          th { 'AOS Az'}
          th { 'Max Az' }
          th { 'Maz El' }
          th { 'LOS Az' }
        end
      end

      tbody do
        if params.passes.count == 0
          tr { td(:col_span => 8) { 'Loading...' } }
        end

        params.passes.each do |pass|
          if pass['aos']['time'] <= state.now.to_i && pass['los']['time'] >= state.now.to_i 
            tr_class = 'success'
          elsif pass['los']['time'] < state.now.to_i  
            tr_class = 'text-muted'
          else
            tr_class = nil
          end

          tr(:class => tr_class) do
            td { pass['sat_id'] }
            td { Time.at(pass['aos']['time']).utc.to_s }
            td { Time.at(pass['max']['time']).utc.to_s }
            td { Time.at(pass['los']['time']).utc.to_s }
            td { pass['aos']['az'].to_s }
            td { pass['max']['az'].to_s }
            td { pass['max']['el'].to_s }
            td { pass['los']['az'].to_s }
          end
        end
      end
    end
  end
end

class UpdatingSatelliteTable < React::Component::Base
  param :poll_interval, :type => Fixnum, :default => 1
  param :sat_ids, :type => [String], :default => nil
  param :coords, :type => [Float], :default => nil

  define_state :sats => []
  define_state :show_tracks => false

  before_mount do
    @fetcher = every(params.poll_interval) do
      HTTP.get(poll_url) do |response|
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
    @fetcher.call # Immediately fetch
  end
  
  before_unmount do
    @fetcher.stop
  end

  def poll_url
    url = "/current?paths=#{state.show_tracks ? '1' : '0'}"
    url += "&ids=#{params.sat_ids.join(',')}" if params.sat_ids
    url += "&from=#{params.coords.join(',')}" if params.coords
    url
  end

  def render
    div do
      label do
        input(:type => 'checkbox', :value => state.show_tracks).on(:change) { |e|
          state.show_tracks! e.target.checked
        }
        'Show tracks'.span(:style => { 'padding-left' => '5px' })
      end
      SatelliteTable(sats: state.sats)
    end
  end
end

class UpdatingPassesTable < React::Component::Base
  param :poll_interval, :type => Fixnum, :default => 60 * 60
  param :sat_ids, :type => [String], :default => nil
  param :coords, :type => [Float]

  define_state :passes => []

  before_mount do
    @fetcher = every(params.poll_interval) do
      HTTP.get(poll_url) do |response|
        if response.ok?
          state.passes! response.json['passes']
        else
          puts "failed with status #{response.status_code}"
        end
      end
    end
  end

  def poll_url
    url = "/passes?ids=#{params.sat_ids.join(',')}"
    url += "&from=#{params.coords.join(',')}"
    url
  end

  after_mount do
    @fetcher.start
    @fetcher.call # Immediately fetch
  end
  
  before_unmount do
    @fetcher.stop
  end

  def render
    PassesTable(:passes => state.passes)
  end
end