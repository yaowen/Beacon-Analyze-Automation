require 'csv'
class AnalyzeJob

  def initialize
    @filters = []
    @result = ""
    @csv = ""  #csv is a Dicionary

    
    @output_dir = ""
    @normal_output_file = nil
    @csv_output_file = nil
  end

  def get_normal_output_file
    if @normal_output_file.nil?
      write_path = @output_filename
      if @output_dir.length > 0
        write_path = @output_dir + "/" + @output_filename
      end
      @normal_output_file = File.open(write_path + ".output", 'w')
    end
    return @normal_output_file
  end

  def get_csv_output_file
    if @csv_output_file.nil?
      write_path = @output_filename
      if @output_dir.length > 0
        write_path = @output_dir + "/" + @output_filename
      end
      @csv_output_file = File.open(write_path + ".csv", 'w')
    end
    return @csv_output_file
  end

  def output_dir= parent_dir
    @output_dir = parent_dir
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

  def flush
    normal_output_file = get_normal_output_file
    normal_output_file.puts @result

    puts @csv
    if @csv != ""
      csv_output_file = get_csv_output_file
      csv_output_file.puts @csv
    end
    @result = ""
    @csv = ""
  end

  def output_result 
    #format the output string by calling the method output_format
    #which should be defined in each analyze job
    output_format
    output_csv_format

    flush
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

