require_relative 'satellite_table'

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