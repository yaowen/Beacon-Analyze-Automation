require 'csv'
require './lib/mongodb_sender'

#Analyze which generate a report divided by day
class DailyReport

  def initialize visit_date
    @visit_date = visit_date
    @filters = []
    @daily_reports = []
    puts "visit_date: " + visit_date.to_s
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
    analyze_daily_session session
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

  def add_filter filter
    @filters << filter
  end

  def flush
    mongo_inst = MongoDBSender.instance
    @daily_reports.each do |daily_report|
      daily_report["timestamp"] = @visit_date.to_time.tv_sec
      mongo_inst.send(@report_name, daily_report)
    end
  end

  def output_result 
    #format the output string by calling the method output_format
    #which should be defined in each analyze job
    output_format
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

