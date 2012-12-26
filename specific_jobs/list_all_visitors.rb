require './analyze_job'
class ListAllVisitorsJob < AnalyzeJob
  
  def initialize
    super
    @visitor_ids = Set.new
    @output_filename = "visitor_id_list"
    @temp_file = File.open("visitors.output", "w")
=begin
    listing_sids_file = File.open("listing.input", "r")
    @listing_sids = Set.new
    listing_sids_file.each do |sid|
      @listing_sids.add sid.gsub("\n", "").gsub("\"", "")
    end
=end
    @version_distribute = {}
    @inconsistency_count = 0
    @session_detail_file = File.new("session_detail.output", "w")
  end
  # ==> methods derivation Has to implement
  #
  def analyze_session session
    @visitor_ids.add session[0]["computerguid"]
=begin
    unless (@listing_sids.include? session[0]["computerguid"])
      return
    end
=end
    @session_detail_file.puts pretty_session_form(session)
    mark_landing = false
    mark_inconsistency = false
    version = ""
    analyze session do |action| 
     if !mark_landing and action["_type"] == "page_load"
        if front_porch? action
          version = extract_version action["pageurl"]
          mark_landing = true
        else
          return
        end
      elsif action["_type"] == "page_load"
        if front_porch? action
          if version != extract_version(action["pageurl"])
            mark_inconsistency = true
          end
        end
      end
    end
    if(mark_inconsistency)
      return
    end
    @version_distribute[version] ||= 0
    @version_distribute[version] += 1
  end

  def output_format
    @version_distribute.each do |version, version_count|
      puts "#{version}  ## #{version_count}"
    end
    @result = ""
    @visitor_ids.each do |visitor_id|
      @temp_file.puts visitor_id
    end
  end
end


