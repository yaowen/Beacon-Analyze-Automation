require './analyze_job'
class VisitNumberCountAnalyzeJob < AnalyzeJob
  
  def initialize
    @visit_count = 0
    @output_filename = "visit_number"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    @visit_count += 1
  end

  def output_format
    @result = @visit_count
  end

end


