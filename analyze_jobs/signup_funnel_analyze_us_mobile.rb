require './analyze_job'
require 'set'
class SignupFunnelUsMobileAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @states_counter = Hash.new
    @output_filename = "signup_funnel"
    @result = ""
    @total = 0
    @total_visits = 0
    @new_users = {}
    @return_uids = {}
    @return_conversion = {}
    @return_users = {}
    @total_visitors = {}
    @used_to = {}
    @browsers = {}
    @os = {}
    @user_version = {}
    @version_count = {}
    @conversion_uids = Set.new
    listing_sids_file = File.open("visitors.output", "r")
    @listing_sids = Set.new
    listing_sids_file.each_line do |line|
      @listing_sids << line.gsub("\n", "")
    end
    puts @listing_sids.length
  end
  # ==> methods derivation Has to implement

  def pick_when action, type, field, target_value
    if action["_type"] == type and action[field] =~ target_value
      
    end
  end

  def add_one counter, field, guid
    key = counter.object_id.to_s + field.to_s
    @used_to[key] ||= Set.new
    return if @used_to[key].include? guid 
    counter[field] ||= 0
    counter[field] += 1
    @used_to[key] << guid
  end

  def formalize
    marks = ["frontporch", "signup_start", "email", "step1", "card", "conversion"]
    @states_counter.each do |key, state_counter|
      marks.each do |mark|
        state_counter[mark] ||= 0
      end
    end
  end

  def analyze_session session
    marks = Set.new
    mark_landing = false
    mark_return_user = false
    mark_other_fp = false
    return if @listing_sids.include? session[0]["computerguid"]
    version = ""
    #this session_count is the real session counter, to count the session number for one computerguid
    computerguid = session[0]["computerguid"]
    version = @user_version[computerguid]
    mark_return_user = (version && version != "")
    mark_landing = mark_landing || mark_return_user
    analyze session do |action|
      sitesessionid = action["sitesessionid"]
      if !mark_landing && action["_type"] == "page_load"
        #@total_visits += 1
        if mobile_signup_start? action 
          mark_landing = true
          abtest_id = action["abtestid"]
          version = extract_version action["pageurl"]
          @new_users[version] ||= {}
          if !@new_users[version].include?(computerguid)
            @new_users[version][computerguid] ||= Set.new
            @new_users[version][computerguid].add sitesessionid
          end
          @browsers[version] ||= {}
          client_str = action["client"].split(" ")[0..1].join(" ").to_s
          @browsers[version][client_str] ||= Set.new
          @browsers[version][client_str].add action["computerguid"]
          @user_version[computerguid] = version
        end
      end

      if mark_landing && !@new_users[version][computerguid].include?(sitesessionid)
	@return_uids[version] ||= Set.new
	@return_uids[version].add computerguid
      end
      
      if action["_type"] == "page_load"
        if mobile_signup_start?(action) && !mark_return_user
          marks.add "signup_start"
        elsif mobile_conversion? action
          @conversion_uids.add action["computerguid"] if mark_landing
          marks.add "conversion" if mark_landing
        end
      end
    end

    unless mark_landing
      return
    end
 
    #add_one @total_visitors, version, session[0]["computerguid"]

    @states_counter[version] ||= {}
    marks.each do |mark|
      add_one @states_counter[version], mark, session[0]["computerguid"]
    end
    formalize
  end

  def output_format
    sort_browsers = {}
    @browsers.each do |version, v_map|
      sort_browsers[version] = @browsers[version].sort do |a, b|
        a[0] <=> b[0]
      end
    end
    conversion_file = File.open('conversion.txt', 'w')
    @conversion_uids.each do |uid|
      conversion_file.puts uid
    end
=begin
    puts "========BROWSERS========="
    sort_browsers["origin"].each do |browser, v_map|
      origin_browser = @browsers["origin"][browser.to_s] || Set.new
      open_browser = @browsers["open.hulu.jp"][browser.to_s] || Set.new
      puts "\t#{browser}: #{origin_browser.length}\t#{open_browser.length}"
    end
    puts "========END============"

    puts "SF Total Visitors: #{@total_visitors}"
    puts "signup funnel total visits: #{@total_visits}"
=end

    puts "========RETURN USERS========="
    @return_uids.each do |version, return_users_v| 
      puts "#{version}: #{return_users_v.length}"
      puts "rate: #{return_users_v.length * 1.0 / @new_users[version].length}"
    end
    puts "=======END================"
    
=begin
    puts "=========RETURN CONV DISTRIBUTE==========="
    @return_conversion.each do |version, return_conversion_distribute|
      return_conversion_distribute.each do |conv_seq, conv_count|
        puts "#{version} #{conv_seq} #{conv_count}"
      end
    end
    puts "=========END============"
=end

    return

    @states_counter.each do |key, state_counter|
      @result += "version: #{key}\n"
      @result += "Landing: #{state_counter["frontporch"]}\n"
      @result += "Signup Start: #{state_counter["signup_start"]}\n"
      @result += "Input Email: #{state_counter["email"]}\n"
      @result += "Step1 Complete: #{state_counter["step1"]}\n"
      @result += "Input CC: #{state_counter["card"]}\n"
      @result += "Conversion: #{state_counter["conversion"]}\n"
    end
  end

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      csv_data << [
        "Version",
        "Signup Start", 
        "Conversion",
        "Conversion Rate"
      ]
      @states_counter.each do |key, state_counter|
        # ==> Head Part

        need_mark = true
        fps = ["signup_start", "conversion"]
	fps.each do |fp|
          need_mark = false if state_counter[fp] < 100
        end
        next unless need_mark
        sessions = @new_users[key].length
        # ==> Value Part
        csv_data << [
          key,
          sessions,
          state_counter["signup_start"],
          state_counter["conversion"],
          format("%.2f%", state_counter["conversion"] * 100.0 / sessions)
        ]
      end
    end
  end

  def output_email_format
    @email_report ||= ""
    @states_counter.each do |key, state_counter|
      landing_count = state_counter["frontporch"] 
      signup_start_rate = state_counter["signup_start"] * 100.0 / landing_count
      email_input_rate = state_counter["email"] * 100.0 / landing_count
      input_credit_card_rate = (state_counter["card"] ) * 100.0 / landing_count
      conversion_rate = state_counter["conversion"] * 100.0 / landing_count
      content = <<-HTML
        <b> version: #{key}, landing: #{state_counter["frontporch"]}, signup_start: #{state_counter["signup_start"]}(#{signup_start_rate}%), email: #{state_counter["email"]}(#{email_input_rate}%), input_credit_card: #{state_counter["card"]}(#{input_credit_card_rate}%), final_conversion: #{state_counter["conversion"]}(#{conversion_rate}%) </b>
      HTML
      @email_report += content
    end
  end
end


