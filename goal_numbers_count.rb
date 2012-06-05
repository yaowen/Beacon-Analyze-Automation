class GoalNumberCountAnalyzeJob
  
  def initialize
    @goal_count = 0
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    analyze session do |action|
      pageurl = action["pageurl"]
      if(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/signup_complete(\?.*)?$/)
         @goal_count += 1
      end
    end
  end

  def output_result
    puts @goal_count
  end

  # ==> common logic for analyze
  def analyze actions
    actions.each do |action|
      yield action
    end
  end
end


