require_relative 'passes_table'

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