module BraheHelpers

  def deg_format(deg)
    "#{deg}°"
  end

  def interval_format(seconds)
    past = (seconds < 0)

    seconds = seconds.to_i.abs

    hours = (seconds / 60 / 60).to_i
    seconds -= hours * 60 * 60

    minutes = (seconds / 60).to_i
    seconds -= minutes * 60

    str = ''

    if hours > 0
      str += "#{'%0d' % hours}h #{'%0d' % minutes}m #{'%02d' % seconds}s"
    elsif minutes > 0
      str += "#{'%0d' % minutes}m #{'%02d' % seconds}s"
    else
      str += "#{'%0d' % seconds}s"
    end

    str += ' ago' if past
    str
  end

  def utc_epoch_time_format(epoch)
    Time.at(epoch).utc.strftime('%b %-e %H:%M:%S')
  end

  def az_format(deg)
    if deg >= 348.75 || deg < 11.25
      'N'
    elsif deg >= 11.25 && deg < 33.75
      'NNE'
    elsif deg >= 33.75 && deg < 56.25
      'NE'
    elsif deg >= 56.25 && deg < 78.75
      'ENE'
    elsif deg >= 78.75 && deg < 101.25
      'E'
    elsif deg >= 101.25 && deg < 123.75
      'ESE'
    elsif deg >= 123.75 && deg < 146.25
      'SE'
    elsif deg >= 146.25 && deg < 168.75
      'SSE'
    elsif deg >= 168.75 && deg < 191.25
      'S'
    elsif deg >= 191.25 && deg < 213.75
      'SSW'
    elsif deg >= 213.75 && deg < 236.25
      'SW'
    elsif deg >= 236.25 && deg < 258.75
      'WSW'
    elsif deg >= 258.75 && deg < 280.75
      'W'
    elsif deg >= 280.75 && deg < 303.75
      'WNW'
    elsif deg >= 303.75 && deg < 326.25
      'NW'
    elsif deg >= 326.25 && deg < 348.75
      'NNW'
    end
  end
end