require './analyze_utils'
require './action_filter'
require 'date'
class TimeActionFilter < ActionFilter
  def initialize
    @start_time = Time.now
    @end_time = Time.now
  end

  def start_time= s_time
    t_time = DateTime.parse(s_time)
    @start_time = t_time.strftime("%Y-%m-%d %H:%M:%S +0900")
  end

  def end_time= e_time
    t_time = DateTime.parse(e_time)
    @end_time = t_time.strftime("%Y-%m-%d %H:%M:%S +0900")
  end
    
  def use_action? action
    visit_time = action["visit_time"]
    return during?(visit_time,
                   @start_time,
                   @end_time)
  end
end
