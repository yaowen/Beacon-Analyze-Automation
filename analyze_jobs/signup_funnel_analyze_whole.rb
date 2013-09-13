require './analyze_job'
require 'set'
class SignupFunnelWholeAnalyzeJob < AnalyzeJob
  
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
    @ignore_uids = Set.new
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
      return if action["os"].downcase.include?("android") || action["os"].downcase.include?("iphone") || action["os"].downcase.include?("ipad") 
      return if action["client"].downcase.include?("unknown version")
      sitesessionid = action["sitesessionid"]
      if !mark_landing && action["_type"] == "page_load"
        #@total_visits += 1
        if front_porch? action 
          mark_landing = true
          abtest_id = action["abtestid"]
          return unless abtest_id == "20130903" || action["pageurl"].include?("open.hulu.jp")
          version = extract_version action["pageurl"]
          #puts action["pageurl"] if "origin" == version #&& action["pageurl"].include?("rdt")
          #return if action["os"].downcase.include?("android") || action["os"].downcase.include?("iphone")
          #return if action["client"].downcase.include?("unknown version")
          #puts version
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
      
      #if action["_type"] == "page_load" && action["pageurl"] =~ /.*promo\/.*/
      #  puts action["pageurl"]
      #  return
      #end
      #if action["_type"] == "page_load" && action["pageurl"] =~ /.*cmp=347.*/
      #  puts action["pageurl"]
      #  return
      #end

      if action["_type"] == "signup_action"
        if action["field"] == "email" and action["event"] = "valid"
          marks.add "email"
        elsif action["field"] == "continue_s2"
          marks.add "step1"
        elsif action["field"] == "card"
          marks.add "card"
        end
      elsif action["_type"] == "page_load"
        if front_porch?(action) && !mark_return_user
          marks.add "frontporch"
        elsif other_front_porch?(action)
          @ignore_uids.add computerguid
        elsif conversion? action
          @conversion_uids.add action["computerguid"] if mark_landing
=begin
          if mark_landing
            sessions_until_convert = @new_users[version][computerguid].length
            sessions_until_convert = 5 if sessions_until_convert > 5
            @return_conversion[version] ||= {}
            @return_conversion[version][sessions_until_convert] ||= 0
            @return_conversion[version][sessions_until_convert]  += 1
          end
=end
          marks.add "conversion" if mark_landing
        elsif signup_start? action
          marks.add "signup_start"
        end
      end
    end

    unless mark_landing
      return
    end
 
    if @ignore_uids.include? computerguid
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
        "Landing", 
        "Signup Start", 
        "Input Email", 
        "Step1 Complete",
        "Input CC", 
        "Conversion",
        "Landing->Signup Start",
        "Signup Start->Input Email",
        "Input Email->Step1 Complete",
        "Step1 Complete->Input CC",
        "Input CC->Conversion",
        "Step1 Complete Rate",
        "Conversion Rate"
      ]
      @states_counter.each do |key, state_counter|
        # ==> Head Part

        need_mark = true
        fps = ["frontporch", "signup_start", "email", "step1", "card", "conversion"]
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
          state_counter["email"],
          state_counter["step1"],
          state_counter["card"],
          state_counter["conversion"],
          format("%.2f%", state_counter["signup_start"] * 100.0 / sessions),
          format("%.2f%", state_counter["email"] * 100.0 / state_counter["signup_start"]),
          format("%.2f%", state_counter["step1"] * 100.0 / state_counter["email"]),
          format("%.2f%", state_counter["card"] * 100.0 / state_counter["step1"]),
          format("%.2f%", state_counter["conversion"] * 100.0 / state_counter["card"]),
 
          format("%.2f%", state_counter["step1"] * 100.0 / sessions),
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


