require './analyze_job'
require 'date'
class GoalNumberCountAnalyzeJob < AnalyzeJob
  
  def initialize
    @visits = {}
    @goal_count = {}
    @output_filename = "goal_number"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    visit_time = DateTime.parse(session[0]["visit_time"])
    mark_landing = false
    mark_conversion = false

    unless during?(
      session[0]["visit_time"],
      "2012-05-17 22:00:00 +0900",
      "2012-05-22 11:00:00 +0900")
      return
    end

    version = ""
    analyze session do |action|
      if !mark_landing and action["_type"] == "page_load"
        unless front_porch? action
          return false
        end
        mark_landing = true
        version = extract_version action["pageurl"]
      end
      
      if conversion? action
        mark_conversion = true
      end
    end
    @visits[version] ||= {}
    @visits[version][visit_time.wday] ||= 0 
    @visits[version][visit_time.wday] += 1

    if mark_conversion
      @goal_count[version] ||= {}
      @goal_count[version][visit_time.wday] ||= 0
      @goal_count[version][visit_time.wday] += 1
    end
  end

  def output_format
  end

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      csv_data << [
        "Day",
        "Version",
        "Visits",
        "Conversion",
        "Conversion Rate"
      ]
      @visits.each do |version, visit_day_data|
        visit_version_data.each do |weekday, visit_count|
          @goal_count[weekday] ||= {}
          @goal_count[weekday][version] ||= 0
          conversion = @goal_count[weekday][version]
          conversion_rate = conversion * 1.0 / visit_count

          csv_data << [
            weekday.to_s,
            version.to_s,
            visit_count.to_s,
            conversion.to_s,
            conversion_rate.to_s
          ]
        end
      end
    end
  end

end


