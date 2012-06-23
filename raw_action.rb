class RawAction

  def [] key
    return @v_hash[key]
  end

  def initialize
    @action_type = ""
    @key_map = []
    @v_hash = {}
  end

  def load fields, type
    @key_map = fields
    @action_type = type
  end

  def parse_beacon_line line
    parts = line.split(/\t/)
    visit_time = time_build(parts)
    @v_hash["visit_time"] = visit_time
    offset = 4
    @key_map.each_index do |index|
      field_name = @key_map[index]
      @v_hash[field_name] = parts[index + offset]
    end
    @v_hash["_type"] = @action_type
  end

  def to_hash 
    return @v_hash
  end

  def parseInt string
      if string =~ /^0\d*$/
          Integer(string[1..-1])
      else
          Integer(string)
      end
  end

  def time_build parts
    year_idx = 0
    month_idx = 1
    day_idx = 2

    year = parseInt(parts[year_idx])
    month = parseInt(parts[month_idx])
    day = parseInt(parts[day_idx])
      
    timeofday = parts[3]
    timeofday_parts = timeofday.split(":")
    hour = parseInt(timeofday_parts[0])
    minute = parseInt(timeofday_parts[1])
    second = parseInt(timeofday_parts[2])
    complete_time = Time.new(year,month,day,hour,minute,second, "+00:00")
  end

  def date_str 
    visit_time = @v_hash["visit_time"]
    return visit_time.strftime("%Y%m%d")
  end
end

