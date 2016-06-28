class SatelliteCalcs
  attr_reader :sat, :site

  def initialize(sat, site)
    @sat = sat
    @site = site
  end

  def footprint_radius
    alt = sat.current_position.altitude
    r = Orbit::OrbitGlobals::XKMPER
    h = alt / 1000.0
    d = Math.sqrt((2 * r * h) + (h * h))
    angle = Math.asin(d / (r + h))
    angle * r
  end

  def path
    positions = []
    start_time = Time.now - (30 * 60)
    end_time = Time.now + (30 * 60)
    interval = 5 * 60

    time = start_time
    begin
      position = sat.position_at_time(time)
      positions << self.class.position_to_hash(position)
    end while (time += interval) <= end_time

    positions
  end

  def next_passes(options={})
    min_el = options[:min_el] || 5
    start_time = options[:start_time] || Time.now
    end_time = options[:end_time] || start_time + (72 * 60 * 60)

    passes = []
    time = start_time
    search_interval = 60
    calc_interval = 5
    current_pass = nil

    while time <= end_time do
      time += search_interval
      look = site.view_angle_to_satellite_at_time(sat, time)
      if look.elevation > 0 && current_pass == nil
        puts "Found a new pass at #{time}"
        current_pass = {
          :max => { :el => 0 }
        }

        # Search backwards for AOS
        while look.elevation >= 0 do
          time -= calc_interval
          look = site.view_angle_to_satellite_at_time(sat, time)
        end

        puts "AOS: #{time}"
        aos_time = time

        # Search forwards for LOS
        begin
          time += calc_interval
          look = site.view_angle_to_satellite_at_time(sat, time)
        end while look.elevation >= 0

        puts "LOS: #{time}"
        los_time = time

        # Calculate the peak (halfway between AOS and LOS)
        max_time = aos_time + ((los_time - aos_time) / 2)

        current_pass[:aos] = look_to_hash(aos_time)
        current_pass[:max] = look_to_hash(max_time)
        current_pass[:los] = look_to_hash(los_time)
        current_pass[:sat_id] = sat.tle.norad_num

        if current_pass[:max][:el] >= min_el
          passes << current_pass 
        end

        current_pass = nil
      end
    end

    passes
  end

  def look_to_hash(time)
    look = site.view_angle_to_satellite_at_time(sat, time)

    {
      :az => Orbit::OrbitGlobals.rad_to_deg(look.azimuth).to_i,
      :el => Orbit::OrbitGlobals.rad_to_deg(look.elevation).to_i,
      :time => time.to_i
    }
  end

  def self.position_to_hash(pos)
    {
      :lat => pos.latitude.round(6),
      :lng => pos.longitude.round(6),
      :alt_km => (pos.altitude / 1000.0).to_i
    }
  end

end