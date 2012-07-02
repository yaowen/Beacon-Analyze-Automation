require './analyze_job'
class PageViewCountAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @pv_count = 0
    @output_filename = "page_view_number.output"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    analyze session do |action|
       @pv_count += 1
    end
  end

  def output_format
    @result = @pv_count
  end
end


