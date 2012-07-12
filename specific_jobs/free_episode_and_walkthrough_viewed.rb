require './analyze_job'
require 'set'
require 'net/http'

#Analyze Free Episode and Walkthrough
class PreviewWatch_v2_SpecificAnalyzeJob < AnalyzeJob
  def initialize
    super
    @total_visitors = {}
    @total_conversions = {}

    @watch_conversions = Hash.new
    @watch_visitors = Hash.new
    @output_filename = "preview_watch"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    watched_video_set = Set.new
    conversion_complete = false
    
    mark_landing = false
    mark_playstart = false
    mark_homepage = false
    version = ""
    analyze session do |action|
      if !mark_landing && action["_type"] == "page_load"
        if front_porch? action
          mark_landing = true
          version = extract_version action["pageurl"] 
        end
      end

      if action["_type"] == "play_action"
        if mark_playstart and action["packageid"] == "4" and action["contentid"] != "40034146"
          mark_homepage = true
          #puts "package_id: " + action["packageid"] + " " + action["contentid"] + " " + action["client"]
        end
        
        if action["client"] == "PlugIn" or action["client"] == "ActiveX" or action["client"] == "Panasonic"
          #puts "IPad"
          next
        elsif action["packageid"] == "4" and action["contentid"] == "40034146" and mark_playstart
          #puts "Walk Through" if mark_homepage
          watched_video_set.add "Walk Through Finish Load"
          mark_playstart = false
          mark_homepage = false
        elsif mark_playstart
          #puts "Home Preview Start "
          watched_video_set.add "Homepage Preview Start"
          mark_playstart = false
        elsif action["packageid"] == "4" or action["packageid"] == "5" 
          watched_video_set.add "Free Episode and 90s"
        else
          #puts action["packageid"] + " " + action["contentid"]
        end
      elsif action["_type"] == "slider_action"
        mark_playstart = true
        if action["contentid"] == "40034146"
          watched_video_set.add "Walk Through Start"
        else
          watched_video_set.add "Homepage Preview Start"
        end
      elsif action["_type"] == "page_load"
        if conversion? action
          conversion_complete = true
        end
      end
    end

    unless mark_landing
      return
    end
    if conversion_complete
      @total_conversions[version] ||= 0
      @total_conversions[version] += 1
      watched_video_set.each do |content_id|
        @watch_conversions[version] ||= {}
        @watch_conversions[version][content_id] ||= 0
        @watch_conversions[version][content_id] += 1
      end 
    end
    @total_visitors[version] ||= 0
    @total_visitors[version] += 1
    watched_video_set.each do |content_id|
      @watch_visitors[version] ||= {}
      @watch_visitors[version][content_id] ||= 0
      @watch_visitors[version][content_id] += 1
    end 
  end

  def output_format
    @result = ""
    return
  end

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      csv_data << [
        "Version",
        "Category",
        "Watched Visitors",
        "Watched Rate",
        "Conversion",
        "Conversion Rate",
        "Improvement",
        "Total Conversion Rate"
      ]
      @watch_visitors.each do |version, watch_visitor_counter|
        @total_conversions[version] ||= 0
        conversion_rate_total = @total_conversions[version] * 1.0 / @total_visitors[version]
        csv_data << [
          "Total Conversion Rate",
          conversion_rate_total.to_s
        ]
        watch_visitor_counter.each do |content_id, watch_count|
          @watch_conversions[version] ||= {}
          @watch_conversions[version][content_id] ||= 0
          conversion = @watch_conversions[version][content_id]
          conversion_rate = conversion * 1.0 / watch_count
          watch_rate = watch_count * 1.0 / @total_visitors[version]
          improvement = conversion_rate * 1.0 / conversion_rate_total - 1

          csv_data << [
            version,
            content_id,
            watch_count.to_s,
            watch_rate.to_s,
            conversion.to_s,
            conversion_rate.to_s,
            improvement.to_s,
            conversion_rate_total.to_s
          ]
        end
      end
    end
  end

  def output_email_format
    @email_report = ""
  end
end


