require 'opal'
require 'browser/interval'
require 'opal-jquery'
require 'opal-activesupport'
require 'json'
require 'react'
require 'react-dom'
require 'reactrb'
require 'helpers'

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

  React.render(React.create_element(UTCClock), Element['#utc-clock'])
end

class SatelliteTable < React::Component::Base
  param :sats, :type => [Hash], :default => []

  def render
    table :class => 'table table-hover' do
      thead do
        tr do
          th { 'Name' }
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
  include BraheHelpers

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
          th(:class => 'interval') { 'Duration' }
          th(:class => 'num') { 'Max El' }
          th(:class => 'border-left border-right center', :col_span => 3) { 'AOS' }
          th(:class => 'border-left border-right center', :col_span => 3) { 'Max' }
          th(:class => 'border-left border-right center', :col_span => 3) { 'LOS' }
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
            td { pass['sat_name'] }
            td(:class => 'interval') { interval_format(pass['los']['time'] - pass['aos']['time']) }
            td(:class => 'num') { "#{pass['max']['el'].to_s}°" }

            td(:class => 'interval border-left') { interval_format(pass['aos']['time'] - Time.now.to_i) }
            td(:class => 'center') { utc_epoch_time_format(pass['aos']['time']) }
            td(:class => 'az border-right') { az_format(pass['aos']['az']) }

            td(:class => 'interval border-left') { interval_format(pass['max']['time'] - Time.now.to_i) }
            td(:class => 'center') { utc_epoch_time_format(pass['max']['time']) }
            td(:class => 'az border-right') { az_format(pass['max']['az']) }

            td(:class => 'interval border-left') { interval_format(pass['los']['time'] - Time.now.to_i) }
            td(:class => 'center') { utc_epoch_time_format(pass['los']['time']) }
            td(:class => 'az border-right') { az_format(pass['los']['az']) }
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
  define_state :now => Time.now

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

  before_mount do
    @updater = every(60) do
      state.now! Time.now
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

    @updater.start
  end

  before_unmount do
    @fetcher.stop
    @updater.stop
  end

  def upcoming_passes
    # Don't display passes older than 5 minutes
    min_time = state.now.to_i - (5 * 60)
    state.passes.select { |p| p['los']['time'] > min_time }
  end

  def render
    PassesTable(:passes => upcoming_passes)
  end
end

class UTCClock < React::Component::Base
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
    state.now.utc.to_s
  end
end
