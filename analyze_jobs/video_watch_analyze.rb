require './analyze_job'
require 'set'
require 'net/http'
class VideoWatchAnalyzeJob < AnalyzeJob
  
  def initialize
    @watch_conversions = Hash.new
    @watch_visitors = Hash.new
    @output_filename = "video_watch.output"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    watched_video_set = Set.new
    conversion_complete = false
    analyze session do |action|
      if action["_type"] == "PlayAction"
        watched_video_set.add action["content_id"]  
      elsif action["_type"] == "PageViewAction" 
        if conversion? action
          conversion_complete = true
        end
      end
    end
    if conversion_complete
      watched_video_set.each do |content_id|
        @watch_conversions[content_id] ||= 0
        @watch_conversions[content_id] += 1
      end 
    end
    watched_video_set.each do |content_id|
      @watch_visitors[content_id] ||= 0
      @watch_visitors[content_id] += 1
    end 
  end

  def get_video_name content_id
    uri = URI("http://rest.internal.hulu.com/videos/?content_id=#{content_id}")
    res = Net::HTTP.get_response(uri)
    return res.body.scan(/<title>(.*?)<\/title>/)[0][0]
  end

  def output_format
    @result = ""
    sorted_map = @watch_visitors.sort do |a, b|
      @watch_conversions[a[0]] ||= 0
      @watch_conversions[b[0]] ||= 0
      (@watch_conversions[a[0]] * 1.0 / a[1]) <=> (@watch_conversions[b[0]] * 1.0 / b[1])
    end
    linecount = 0
    sorted_map.each do |content_id, count|
      if count < 50
        next
      end
      linecount += 1
      print("#{linecount}\r")
      @watch_conversions[content_id] ||= 0
      @result += "video: #{get_video_name content_id} -- watched people: #{count}, conversion rate: #{@watch_conversions[content_id] * 100.0 / @watch_visitors[content_id]} %\n"
    end
  end
end


