require './analyze_job'
require 'date'
class ViewedPageCountWholeAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @visits = {}
    @page_view = {}
    @output_filename = "viewed_page"
    @result = ""
    @total_visitors = {}
    @used_to = {}
    @user_version = {}
    @ignore_uids = Set.new
    listing_sids_file = File.open("visitors.output", "r")
    @listing_sids = Set.new
    listing_sids_file.each_line do |line|
      @listing_sids << line.gsub("\n", "")
    end
    puts @listing_sids.length
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
    visit_time = DateTime.parse(session[0]["visit_time"])
    mark_landing = false
    mark_conversion = false

    viewed_pages = Set.new

    version = ""
    return if @listing_sids.include? session[0]["computerguid"]
    
    computerguid = session[0]["computerguid"]
    version = @user_version[computerguid]
    mark_return_user = (version && version != "")
    mark_landing = mark_landing || mark_return_user
    analyze session do |action|
      return if action["os"].downcase.include?("android") || action["os"].downcase.include?("iphone") || action["os"].downcase.include?("ipad")
      return if action["client"].downcase.include?("unknown version")
      if !mark_landing and action["_type"] == "page_load"
        if front_porch? action
          mark_landing = true
          version = extract_version action["pageurl"]
          abtest_id = action["abtestid"]
          return unless abtest_id == "20130903" || action["pageurl"].include?("open.hulu.jp")
          version = extract_version action["pageurl"]
          @user_version[computerguid] = version
          #puts action["pageurl"] if "origin" == version #&& action["pageurl"].include?("rdt")
        end
      end
      
      if action["_type"] == "page_load"
        if conversion? action
          mark_conversion = true
        elsif other_front_porch?(action)
          @ignore_uids.add computerguid
        else
          pageurl = action["pageurl"]
          pageurl = pageurl.split("?")[0]
          viewed_pages.add(pageurl)
        end
      end
    end

    unless mark_landing
      return
    end
   
    if @ignore_uids.include? computerguid
      return
    end

    @page_view[version] ||= {}
    viewed_pages.each do |viewed_page|
      add_one @page_view[version], viewed_page, session[0]["computerguid"]
    end

    add_one @visits, version, session[0]["computerguid"]
  end

  def output_format
  end

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      csv_data << [
        "Version",
        "View Page",
        "Visits"
      ]
      @page_view.each do |version, visit_page_data|
        visit_page_data.each do |visit_page, visit_count|
          if (visit_count < 100)
            next
          end
          visit_rate = visit_count * 1.0 / @visits[version]
          if (visit_rate < 0.01)
            next
          end

          csv_data << [
            version.to_s,
            visit_page.to_s,
            visit_count.to_s,
            visit_rate.to_s
          ]
        end
      end
    end
  end
end


