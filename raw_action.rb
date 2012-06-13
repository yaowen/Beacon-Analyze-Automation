class RawAction

  def parse_beacon_line line
  end

  def to_hash 
    v_hash = {:_type => self.class.to_s}
    return v_hash
  end

  def time_build parts
    line_type = check_type(parts)
    year_idx = 0
    month_idx = 1
    day_idx = 2

    year = parseInt(parts[year_idx])
    month = parseInt(parts[month_idx])
    day = parseInt(parts[day_idx])
      
    timeofday = parts[-3]
    timeofday_parts = timeofday.split(":")
    hour = parseInt(timeofday_parts[0])
    minute = parseInt(timeofday_parts[1])
    second = parseInt(timeofday_parts[2])
    complete_time = Time.new(year,month,day,hour,minute,second, "+00:00")
  end
end

