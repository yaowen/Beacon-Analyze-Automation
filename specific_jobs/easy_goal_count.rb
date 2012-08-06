require './analyze_job'
require './lib/plus_token_authentication'
require 'set'
class EasyGoalCount < AnalyzeJob
  include PlusTokenAuthentication
  
  def initialize
    super
    @userids = Set.new
    @sp_userids = Set.new
    @goal_sessions = Set.new
    @output_filename = "easy_goal_view_number"
    @temp_output = File.open("specific_jobs/temp_output.output", "w")
    @result = ""
    init_userids
  end
  
  def init_userids
    file = File.open("specific_jobs/outersec.output")
    file.each_line do |line|
      line = line.gsub("\n", "");
      @sp_userids.add(line)
    end
    puts @sp_userids.length
    file.close 
  end

  def extract_param url, param
    param_part = url.scan(/(\?|&)#{param}=(.*?)(&|$)/)
    if param_part.length == 0
      return url
    end
    param_part = param_part[0][1]
    return param_part
  end


  def analyze_session session
    #puts session
    mark_conversion = false
    userid = ""
    analyze session do |action|
      if action["_type"] == "page_load"
  
        if action.pageurl =~ /signup_complete_mobile/  and action["userid"] != "0"
          utoken = extract_param action["pageurl"], "utoken"
          userid = get_user_from_plus_token(utoken)
            
          @goal_sessions.add action["sitesessionid"]
          @userids.add userid
        end
      end
    end

    
    if userid != ""
      #@temp_output.puts userid
    end

    if @sp_userids.include? userid.to_s
      @temp_output.puts userid.to_s + "#" + session.to_s
    end
  end

  def output_format
    @result += "#{@goal_sessions.length}\n"
    @userids.each do |userid|
      @result += "#{userid}\n"
    end
  end
end


