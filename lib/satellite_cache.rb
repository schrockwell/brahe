class SatelliteCache
  TLE_REGEX = /(.*\n1 .*\n2 [^\n]*)/

  attr_reader :sats

  def initialize(options={})
    @sats = {}
    @url = options[:url]
  end

  def update
    return if @updated_at && (Time.now - @updated_at < 60 * 60)

    tles = open(@url).read
    update_from_tles(tles)
  end

private

  def update_from_tles(tles_str)
    tles = tles_str.scan(TLE_REGEX).map(&:first)

    tles.each do |tle|
      sat = Orbit::Satellite.new(tle)
      @sats[sat.tle.norad_num] = sat
    end

    @updated_at = Time.now
    puts "Updated satellite cache"
  end

end