class TestAnalyzeJob
  # ==> methods derivation Has to implement
  def analyze_session session
    analyze session do |action|
      puts action
    end
  end

  def output_result
  end

  # ==> common logic for analyze
  def analyze actions
    actions.each do |action|
      yield action
    end
  end
end


