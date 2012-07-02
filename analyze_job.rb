require 'csv'
class AnalyzeJob

  def initialize
    @filters = []
    @result = ""
    @csv = ""  #csv is a Dicionary
  end

  # ==> methods derivation Has to implement
  def analyze_session_entry session
    unless need? session
      return
    end
    before_analyze
    analyze_session session
    after_analyze
  end

  def need? session
    @filters.each do |filter|
      unless filter.use_session? session
        return false
      end
    end
    return true
  end

  def before_analyze
  end

  def after_analyze
  end

  def output_csv_format
    @csv = ""
  end

  def add_filter filter
    @filters << filter
  end

  def output_result parent_dir = ""
    #format the output string by calling the method output_format
    #which should be defined in each analyze job
    output_format
    write_path = @output_filename
    if parent_dir.length > 0
      write_path = parent_dir + "/" + @output_filename
    end
    output_file = File.open(write_path + ".output", 'w')
    output_file.puts @result
    
    output_csv_format
    if @csv != ""
      output_file = File.open(write_path + ".csv", 'w')
      output_file.puts @csv
    end
  end

  # ==> common logic for analyze
  def analyze actions
    actions.each do |action|
      yield action
    end
  end

  def before_exit
  end
end

