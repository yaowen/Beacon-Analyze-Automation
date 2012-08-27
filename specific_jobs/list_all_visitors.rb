require './analyze_job'
class ListAllVisitorsJob < AnalyzeJob
  
  def initialize
    super
    @visitor_ids = Set.new
    @output_filename = "visitor_id_list"
    @temp_file = File.open("visitors", "w")
    @pv_count = 0
  end
  # ==> methods derivation Has to implement
  #
  def analyze_session session
    @visitor_ids.add session[0]["computerguid"]
  end

  def output_format
    @result = ""
    @visitor_ids.each do |visitor_id|
      @temp_file.puts visitor_id
    end
  end
end


