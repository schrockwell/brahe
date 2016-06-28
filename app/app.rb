module Brahe
  class App < Sinatra::Base
    configure do
      set :sat_cache, SatelliteCache.new(:url => 'http://www.amsat.org/amsat/ftp/keps/current/nasabare.txt')
    end

    get '/' do
      erb :index, :layout => :layout
    end

    get '/current' do
      settings.sat_cache.update

      site = nil
      if params[:from]
        my_coords = params[:from].split(',').map(&:to_f)
        my_coords[2] = 0 unless my_coords[2]
        site = Orbit::Site.new(*my_coords)
      end

      ids = nil
      if params[:ids]
        ids = params[:ids].split(',')
      end

      include_paths = (params[:paths] == '1')

      results = {
        :satellites => []
      }

      settings.sat_cache.sats.each do |id, sat|
        next if ids && !ids.index(id)

        calc = SatelliteCalcs.new(sat, site)
        sat_result = {}
        results[:satellites] << sat_result

        sat_result[:id] = id
        sat_result[:name] = sat.tle.tle_string.split("\n").first
        sat_result.merge!(SatelliteCalcs.position_to_hash(sat.current_position))
        sat_result[:radius_km] = calc.footprint_radius.round
        sat_result[:path] = calc.path.map { |p| [p[:lat], p[:lng]] } if include_paths

        if site
          topo = site.view_angle_to_satellite_at_time(sat, Time.now)
          sat_result[:look] = {
            :az => Orbit::OrbitGlobals.rad_to_deg(topo.azimuth).round(1),
            :el => Orbit::OrbitGlobals.rad_to_deg(topo.elevation).round(1),
            # :range_km => (topo.range / 1000.0).round(1),
            # :range_rate => topo.range_rate.round(3)
          }
        end
      end

      content_type :json
      results.to_json
    end

    get '/passes' do
      settings.sat_cache.update

      ids = params[:ids].split(',')
      coords = params[:from].split(',').map(&:to_f)
      coords[2] = 0 unless coords[2]
      site = Orbit::Site.new(*coords)

      results = {
        :passes => []
      }

      ids.each do |id|
        sat = settings.sat_cache.sats[id]
        next unless sat

        calc = SatelliteCalcs.new(sat, site)
        results[:passes] += calc.next_passes
      end

      results[:passes].sort! { |p1, p2| p1[:aos][:time] <=> p2[:aos][:time] }

      content_type :json
      results.to_json
    end

    not_found do
      '404'
    end
  end
end