require './daily_report'
require 'date'
class GoalNumberCountReport < DailyReport
  
  def initialize report_date
    super(report_date)
    @visits = {}
    @goal_count = {}
    @conversion_count = {}
    @report_name = "goal_number"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_daily_session session
    mark_landing = false
    mark_conversion = false

    version = ""
    analyze session do |action|
      if !mark_landing and action["_type"] == "page_load"
        if front_porch? action
          mark_landing = true
          version = extract_version action["pageurl"]
        end
      end
      
      if conversion? action
        mark_conversion = true
      end
    end
    @visits[version] ||= 0 
    @visits[version] += 1
    #puts "version: #{version}: #{@visits[version]}"

    if mark_conversion
      @goal_count[version] ||= 0
      @goal_count[version] += 1
    end
  end

  def output_format
    @daily_reports = []
    @visits.each do |version, visit_count|
      daily_report = {}
      daily_report["version"] = version
      daily_report["visits"] = visit_count

      @goal_count[version] ||= 0 #incase
      daily_report["conversions"] = @goal_count[version]
      daily_report["conversion_rate"] = @goal_count[version] * 1.0 / visit_count
      @daily_reports << daily_report
    end
  end
end


