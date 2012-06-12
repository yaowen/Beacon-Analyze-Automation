require './analyze_job'
class GoalNumberCountAnalyzeJob < AnalyzeJob
  
  def initialize
    @goal_count = 0
    @goal_count_from_frontporch = 0
    @output_filename = "goal_number.output"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    frontporch_landing = false
    if isFrontPorch session[0]
      frontporch_landing = true
    end
    analyze session do |action|
      pageurl = action["pageurl"]
      if(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/signup_complete(\?.*)?$/)
         @goal_count += 1
         if(frontporch_landing)
           @goal_count_from_frontporch += 1
         end
      end
    end

  end

  def output_format
    @result += "Total Goal Count: #{@goal_count}\n" 
    @result += "Goal Count after FrontPorch: #{@goal_count_from_frontporch}\n"
  end

end


