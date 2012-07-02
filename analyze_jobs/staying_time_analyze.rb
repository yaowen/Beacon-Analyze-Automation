require './analyze_job'
class StayTimeAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @goal_count = 0
    @output_filename = "stay_time"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    start_time = session[0].visit_time
    end_time = session[session.length - 1].visit_time
  end

  def output_format
  end

end


