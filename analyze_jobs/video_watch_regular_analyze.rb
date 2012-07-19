require './analyze_job'
require 'set'
require 'net/http'
class VideoWatchRegularAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @cache_filepath = "cache/video_info.cache"
    init_video_data

    @watch_conversions = Hash.new
    @watch_visitors = Hash.new

    @show_conversions = Hash.new
    @show_visitors = Hash.new

    @visitors = {}
    @conversions = {}

    @linecount = 0

    @output_filename = "video_watch_regular"
    @result = ""
  end

  def add_cache_tuple tuple
    content_id = tuple["content_id"]
    show_name = tuple["show_name"]
    video_name = tuple["video_name"]

    @video_name_cache[content_id] = video_name
    @show_name_cache[content_id] = show_name
  end

  def init_video_data
    @video_name_cache = Hash.new
    @show_name_cache = Hash.new
    if File.exist? @cache_filepath
      cache_file = File.open(@cache_filepath, 'r')
      cache_file.each_line do |line|
        id_video_info_tuple = JSON.parse(line)
        add_cache_tuple id_video_info_tuple
      end
      cache_file.close
    else
      system("touch cache/video_info.cache")
    end
  end

  def save_video_data
    cache_file = File.open(@cache_filepath, 'w')
    @video_name_cache.each do |content_id, video_name|
      show_name = @show_name_cache[content_id] || video_name
      tuple = {"content_id" => content_id, 
        "show_name" => show_name,
        "video_name" => video_name
      }
      cache_file.puts tuple.to_json
    end
    
  end

  def before_output
    save_video_data
  end

  # ==> methods derivation Has to implement
  def analyze_session session
    watched_video_set = Set.new
    watched_show_set = Set.new
    conversion_complete = false
    
    visit_date = DateTime.parse(session[0]["visit_time"])
    visit_date_str = visit_date.strftime("%Y%m%d")
    @visitors[visit_date_str] ||= 0
    @visitors[visit_date_str] += 1
    analyze session do |action|
      if action["_type"] == "play_action"
        show_type = action["packageid"] == "4" ? "free" : "90s"
        watched_video_set.add action["contentid"]  
        puts action["contentid"]
        watched_show_set.add(get_show_name(action["contentid"]) + "#" + show_type)
      elsif action["_type"] == "page_load" 
        if conversion? action
          conversion_complete = true
        end
      end
    end
    if conversion_complete
      @conversions[visit_date_str] ||= 0
      @conversions[visit_date_str] += 1
      watched_video_set.each do |content_id|
        @watch_conversions[content_id] ||= 0
        @watch_conversions[content_id] += 1
      end 

      watched_show_set.each do |show_name|
        @show_conversions[visit_date_str] ||= {}
        @show_conversions[visit_date_str][show_name] ||= 0
        @show_conversions[visit_date_str][show_name] += 1
      end
    end
    watched_video_set.each do |content_id|
      @watch_visitors[content_id] ||= 0
      @watch_visitors[content_id] += 1
    end 
    watched_show_set.each do |show_name|
      @show_visitors[visit_date_str] ||= {}
      @show_visitors[visit_date_str][show_name] ||= 0
      @show_visitors[visit_date_str][show_name] += 1
    end

  end

  def get_video_name content_id
    if @video_name_cache[content_id].nil?
      generate_video_info content_id
    end
    return @video_name_cache[content_id]
  end

  def get_show_name content_id
    if @show_name_cache[content_id].nil?
      generate_video_info content_id
    end
    return @show_name_cache[content_id]
  end

  def generate_video_info content_id
    begin
    unless @video_name_cache[content_id].nil?
      return @video_name_cache[content_id]
    end

    @linecount += 1
    print("download video info: #{@linecount} and video_name_cache size is: #{@video_name_cache.length}\r")
    save_video_data if @linecount % 20 == 0

    uri = URI("http://rest.internal.hulu.com/videos/?content_id=#{content_id}")
    res = Net::HTTP.get_response(uri)
    body = res.body.gsub("\n", "")
    
    content = ""
    video_type = body.scan(/<video-type>(.*?)<\/video-type>/)[0][0]

    if video_type == "episode"
      show_name = body.scan(/<show>.*?<name>(.*?)<\/name>.*?<\/show>/)[0][0]
      season_number = body.scan(/<season-number.*?>(.*?)<\/season-number.*?>/)[0][0]
      episode_number = body.scan(/<episode-number.*?>(.*?)<\/episode-number.*?>/)[0][0]
      content = "#{show_name}-#{season_number}-#{episode_number}"
    else
      content = body.scan(/<title>(.*?)<\/title>/)[0][0]
    end

    @video_name_cache[content_id] = content
    @show_name_cache[content_id] = show_name || content
    rescue
      content = "Error Occurs"
    end
    return content
  end

  def sort_by_conversion_rate visitor_container, conversion_container
    sorted_map = visitor_container.sort do |a, b|
      conversion_container[a[0]] ||= 0
      conversion_container[b[0]] ||= 0
      (conversion_container[a[0]] * 1.0 / a[1]) <=> (conversion_container[b[0]] * 1.0 / b[1])
    end
    return sorted_map
  end

  def output_format
    @result = ""
  end

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      @show_visitors.each do |visit_date_str, show_visitor_daily|
        csv_data << [visit_date_str]
        csv_data << [
          "ShowName",
          "Watched Visitors",
          "Watched Rate",
          "Conversion",
          "Conversion Rate",
          "Improvement"
        ]
        # ==> Value Part
        show_conversion_daily = @show_conversions[visit_date_str] || {}
        visitor_daily = @visitors[visit_date_str]
        conversion_daily = @conversions[visit_date_str]
        conversion_rate_total = conversion_daily * 1.0 / visitor_daily
        sorted_map = sort_by_conversion_rate show_visitor_daily, show_conversion_daily
        sorted_map.each do |content_id, count|
          if count < 50 
            next
          end
          conversion = show_conversion_daily[content_id] || {}
          conversion_rate = show_conversion_daily[content_id] * 1.0 / show_visitor_daily[content_id]
          watch_rate = count * 1.0 / visitor_daily
          improvement = conversion_rate * 1.0 / conversion_rate_total - 1 

          csv_data << [
            content_id,
            count.to_s,
            watch_rate.to_s,
            conversion.to_s,
            conversion_rate.to_s,
            improvement.to_s
          ]
        end
      end
    end
  end

  def output_email_format
    @email_report = ""
  end
end


