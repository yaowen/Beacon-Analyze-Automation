require './analyze_job'
require 'set'
require 'net/http'
class PreviewWatchWholeAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @total_visitors = {}
    @total_conversions = {}

    @watch_conversions = Hash.new
    @watch_visitors = Hash.new
    @output_filename = "preview_watch"
    @user_version = {}
    @ignore_uids = Set.new
    @result = ""
    listing_sids_file = File.open("visitors.output", "r")
    @listing_sids = Set.new

    listing_sids_file.each_line do |line|
      @listing_sids << line.gsub("\n", "")
    end
    @used_to = {}
  end

  def add_one counter, field, guid 
    key = counter.object_id.to_s + field.to_s
    @used_to[key] ||= Set.new
    return if @used_to[key].include? guid 
    counter[field] ||= 0
    counter[field] += 1
    @used_to[key] << guid
  end

  # ==> methods derivation Has to implement
  def analyze_session session
    watched_video_set = Set.new
    conversion_complete = false
    
    mark_landing = false
    mark_return_user = false
    #return if @listing_sids.include? session[0]["computerguid"]
    version = ""
    trailerids = [
	"60248999",
	"60244792",
	"60249412",
	"60229228",
	"60245135",
	"60249805",
	"60244231",
	"60244801",
	"60244794",
	"60244828",
	"60244782",
	"60244802",
	"60244827",
	"60245143"
    ]

    computerguid = session[0]["computerguid"]
    version = @user_version[computerguid]
    mark_return_user = (version && version != "")
    mark_landing = mark_landing || mark_return_user
    analyze session do |action|
      return if action["os"].downcase.include?("android") || action["os"].downcase.include?("iphone") || action["os"].downcase.include?("ipad")
      return if action["client"].downcase.include?("unknown version")
      if !mark_landing && action["_type"] == "page_load"
        if front_porch? action
          mark_landing = true
          abtest_id = action["abtestid"]
          return unless abtest_id == "20130903" || action["pageurl"].include?("open.hulu.jp")
          version = extract_version action["pageurl"]
          @user_version[computerguid] = version
        end
      end
      if action["_type"] == "play_action"
        if trailerids.include?(action["contentid"])
          watched_video_set.add "Trailers"
        elsif action["packageid"] == "4" 
          watched_video_set.add "Free Episode"
        elsif action["packageid"] == "5"
          watched_video_set.add "90s"
        end
        if action["contentid"] == "40034146"
          watched_video_set.add "Intro Video"
        end
      elsif action["_type"] == "slider_action"
        if action["pageurl"] =~ /^http:\/\/www2\.hulu\.jp\/?(\?.*)?$/
          watched_video_set.add "Homepage Preview"
        end
      elsif action["_type"] == "page_load" 
        if conversion? action
          conversion_complete = true
        elsif other_front_porch? action
          @ignore_uids.add computerguid
        end
      end
    end

    unless mark_landing
      return
    end

    if @ignore_uids.include? computerguid
      return
    end
    @watch_conversions[version] ||= {}
    if conversion_complete
      add_one @total_conversions, version, session[0]["computerguid"]
      watched_video_set.each do |content_id|
        add_one @watch_conversions[version], content_id, session[0]["computerguid"]
      end 
    end
    add_one @total_visitors, version, session[0]["computerguid"]
    @watch_visitors[version] ||= {}
    watched_video_set.each do |content_id|
      add_one @watch_visitors[version], content_id, session[0]["computerguid"]
    end 
  end

  def output_format
    #puts "Total Visitors: #{@total_visitors}"
    #@result = @total_visitors
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
        next if @total_conversions[version] < 20
        conversion_rate_total = @total_conversions[version] * 100.0 / @total_visitors[version]
        csv_data << [
          "Total Conversion Rate",
          conversion_rate_total.to_s,
          "Total Visitors",
          @total_visitors[version]
        ]
        preview_types = ["Homepage Preview", "90s", "Free Episode", "Intro Video", "Trailers"]
        preview_types.each do |content_id|
          watch_count = watch_visitor_counter[content_id] || 0
          @watch_conversions[version] ||= {}
          @watch_conversions[version][content_id] ||= 0
          conversion = @watch_conversions[version][content_id] || 0
          next if conversion == 0
          conversion_rate = conversion * 100.0 / watch_count
          watch_rate = watch_count * 100.0 / @total_visitors[version]
          improvement = (conversion_rate * 1.0 / conversion_rate_total - 1) * 100.0
             
          csv_data << [
            version,
            content_id,
            watch_count.to_s,
            format("%.2f%", watch_rate),
            conversion.to_s,
            format("%.2f%", conversion_rate),
            format("%.2f%", improvement),
            format("%.2f%", conversion_rate_total)
          ]
        end
      end
    end
  end

  def output_email_format
    @email_report = ""
  end
end


