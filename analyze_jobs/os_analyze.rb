require './analyze_job'
class OSAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @os_count = {}
    @client_count = {}
    @goal_os_count = {}
    @goal_client_count = {}
    @visit_count = 0
    @output_filename = "os_client_analyze.output"
    @result = ""
  end

  def os_name_reduce os_name
    if os_name =~ /^Linux.*Android.*/
      return "Linux Android"
    elsif os_name =~ /^Windows.*/
      return "Windows"
    elsif os_name =~ /^Mac.*/
      return "Mac"
    else 
      return "Other"
    end
  end

  def client_name_reduce client_name
    return client_name
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    os = session[0]["os"]
    client = session[0]["client"]
    os = os_name_reduce(os)
    @os_count[os] ||= 0
    @os_count[os] += 1
    client = client_name_reduce(client)
    @client_count[client] ||= 0
    @client_count[client] += 1
    analyze session do |action|
      pageurl = action["pageurl"]
      if(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/signup_complete(\?.*)?$/)
         @goal_client_count[client] ||= 0
         @goal_client_count[client] += 1
         @goal_os_count[os] ||= 0
         @goal_os_count[os] += 1
      end
    end
    @visit_count += 1
  end

  def output_format
    @result += "========OS Distribution=======\n"
    @os_count.each do |os_name, os_number|
      @goal_os_count[os_name] ||= 0
      @result += "#{os_name}\t#{os_number}\t#{os_number * 100.0 / @visit_count}%  conversion: #{@goal_os_count[os_name] * 100.0 / os_number}% \n"
    end
    @result += "========Client Distribution ========\n"
    @client_count.each do |client_name, client_number|
      @goal_client_count[client_name] ||= 0
      @result += "#{client_name}\t#{client_number}\t#{client_number * 100.0 / @visit_count}% conversion: #{@goal_client_count[client_name] * 100.0 / client_number}%\n"
    end
  end
end


