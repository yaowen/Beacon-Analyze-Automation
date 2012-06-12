class AnalyzeJob

  # ==> methods derivation Has to implement
  def analyze_session session
  end

  def output_result parent_dir = ""
    #format the output string by calling the method output_format
    #which should be defined in each analyze job
    output_format
    write_path = @output_filename
    if parent_dir.length > 0
      write_path = parent_dir + "/" + @output_filename
    end
    output_file = File.open(write_path, 'w')
    output_file.puts @result
  end

  # ==> common logic for analyze
  def analyze actions
    actions.each do |action|
      yield action
    end
  end
end

