require './analyze_utils'
require 'date'
require './session_filter'
class TimeSessionFilter < SessionFilter
  def initialize
    @start_time = ""
    @end_time = ""
  end

  def start_time= s_time
    t_time = DateTime.parse(s_time)
    @start_time = t_time.strftime("%Y-%m-%d %H:%M:%S +0900")
  end

  def end_time= e_time
    t_time = DateTime.parse(e_time)
    @end_time = t_time.strftime("%Y-%m-%d %H:%M:%S +0900")
  end
    

  #judge according to the first action of the session
  def use_session? session
    visit_time = session[0]["visit_time"]
    return during?(visit_time,
                   @start_time,
                   @end_time)
  end
end
