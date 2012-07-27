require './analyze_job'
require 'set'
class VisitNumberCountAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @visit_count = {}
    @output_filename = "visit_number"
    @result = ""
    @sids = {}
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    mark_fp = false
    mark_conversion = false
    version = ""
    analyze session do |action|
      if front_porch? action and !mark_fp
        version = extract_version(action["pageurl"])
        @visit_count[version] ||= 0
        @visit_count[version] += 1
        mark_fp = true
      end
      if conversion? action
        mark_conversion = true
      end
    end
    unless mark_fp
      return
    end
    @sids["total"] ||= Set.new
    @sids["total"].add session[0]["sitesessionid"]
    puts "total"
    @sids[version] ||= Set.new
    @sids[version].add session[0]["sitesessionid"]
    #if !@sids["201207162"].nil?
    #  puts @sids["201207162"].length
    #end
    if mark_conversion 
      @sids["conversion"] ||= Set.new
      @sids["conversion"].add session[0]["sitesessionid"]
    end
  end

  def output_format
    @visit_count.each do |version, vc|
      @result += "#{version}, #{vc}\n"
    end
    @sids.each do |version, sid_set|
      file = File.open("visits_number_#{version}.output", "w")
      sid_set.each do |sid|
        file.puts "#{sid}"
      end
      file.close
    end
  end
end


