require './analyze_job'
require 'set'
require 'net/http'
require 'date'

#Analyze Avg duration from load the player to actually play
class LoadToPlayDurationAnalyzeJob < AnalyzeJob
  def initialize
    super
    @total_diff = 0
    @total_count = 0
    @output_filename = "load_to_play"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    watched_video_set = Set.new
    conversion_complete = false
    
    mark_landing = false
    mark_playstart = false
    version = ""

    load_timestamp = ""
    start_timestamp = ""
    analyze session do |action|
      if action["_type"] == "play_action"
        if action["client"] == "PlugIn" or action["client"] == "ActiveX" or action["client"] == "Panasonic"
          next
        elsif action["packageid"] == "4" and action["contentid"] = "40034146" and mark_playstart
          watched_video_set.add "Walk Through Finish Load"
          mark_playstart = false
          start_timestamp = DateTime.parse(action["visit_time"])
          time_diff = (start_timestamp - load_timestamp) * 1.0 * 24 * 60 * 60
          if time_diff > 6 
            next
          end
          puts time_diff
          @total_diff = @total_diff + time_diff
          @total_count += 1
        end
      elsif action["_type"] == "slider_action"
        if action["contentid"] == "40034146"
          mark_playstart = true
          load_timestamp = DateTime.parse(action["visit_time"])
        end
      end
    end

  end

  def output_format
    @result = @total_diff * 1.0 / @total_count
    return
  end

  def output_csv_format
  end

  def output_email_format
    @email_report = ""
  end
end


