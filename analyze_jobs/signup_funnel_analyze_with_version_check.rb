require './analyze_job'
require 'set'
class SignupFunnelWithVersionCheckAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @states_counter = Hash.new
    @output_filename = "signup_funnel"
    @error_log = File.open("version_inconsist.log", "w")
    @version_output = File.open("version_detail.log", "w")
    
    @old_users = Set.new
    listing_input = File.open("listing.input", "r")
    listing_input.each do |cid|
      @old_users.add cid.gsub("\"", "").gsub("\n", "")
    end
    @new_users = {}

    @result = ""
    @total = 0
    @total_visits = 0
    @watch_count = 0 
    @return_uids = {}
    @return_users = {}
    @old_visitors = {}
    @old_visitors_conversion = {}
    @inconsistency_sessions = {}
  end
  # ==> methods derivation Has to implement

  def pick_when action, type, field, target_value
    if action["_type"] == type and action[field] =~ target_value
      
    end
  end

  def add_one counter, field
    counter[field] ||= 0
    counter[field] += 1
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
    mark_target = false
    mark_watch = false
    mark_inconsistency = false
    mark_return = false
    version = ""
    #if @old_users.include? session[0]["computerguid"] 
    #  analyze session do |action|
    #    if action["_type"] == "page_load" && front_porch?(action)
    #      version = extract_version action["pageurl"]
    #      @old_visitors[version] ||= 0 
    #      @old_visitors[version] += 1
    #    elsif action["_type"] == "page_load" && conversion?(action)
    #      @old_visitors_conversion[version] ||= 0
    #      @old_visitors_conversion[version] += 1
    #    end
    #  end
    #  return
    #end
    analyze session do |action|
      if !mark_landing and action["_type"] == "page_load"
        @total_visits += 1
        if front_porch? action
          version = extract_version action["pageurl"]
          abtest_id = action["abtestid"]
          @new_users[version] ||= Set.new
          if @new_users[version].include? action["computerguid"]
            @return_uids[version] ||= Set.new
            @return_uids[version].add action["computerguid"]
            @return_users[version] ||= 0
            @return_users[version] += 1
            return
          end
          @new_users[version].add action["computerguid"]
          mark_landing = true
        else
          #return
        end
      end
      if action["_type"] == "signup_action"
        if action["field"] == "email" and action["event"] = "valid"
          marks.add "email"
        elsif action["field"] == "continue_s2"
          marks.add "step1"
        elsif action["field"] == "card"
          marks.add "card"
        end
      elsif action["_type"] == "page_load"
        if action["pageurl"].include? "201207252"
          mark_target = true
        end
        if front_porch? action
          if version != extract_version(action["pageurl"])
            puts "#{version} ## #{extract_version(action["pageurl"])}"
            mark_inconsistency = true
          end
          marks.add "frontporch"
        elsif conversion? action
          marks.add "conversion"
        elsif signup_start? action
          marks.add "signup_start"
        end
      elsif action["_type"] == "play_action" or action["_type"] == "slider_action"
        mark_watch = true
      end
    end

    if mark_watch
      if mark_landing
        @watch_count += 1
      end
      #return
    else
      #return
    end
    
=begin
    if mark_target
      @version_output.puts session[0]["sitesessionid"]
      if mark_inconsistency
        @error_log.puts session[0]["sitesessionid"]
      elsif version != "201207252"
        #puts "version: #{version} " + session[0]["sitesessionid"]
      end
    end
=end

    unless mark_landing
      return
    end

    if mark_inconsistency
      puts pretty_session_form session
      @inconsistency_sessions[version] ||= 0
      @inconsistency_sessions[version] += 1
      return
    end

    @states_counter[version] ||= {}
    marks.each do |mark|
      add_one @states_counter[version], mark
    end
    formalize
  end

  def output_format
    puts "signup funnel total visits: #{@total_visits}"
    puts "watch_count #{@watch_count}"
    #@old_visitors.each do |version, count|
    #  @old_visitors_conversion[version] ||= 0
    #  puts "#{version} ## #{count} ## #{@old_visitors_conversion[version]}"
    #end
    puts "###########new users###############"
    @new_users.each do |version, uidset|
      puts "#{version} ## #{uidset.length} }"
    end
    puts "###########return users###############"
    @return_users.each do |version, count|
      puts "#{version} ## #{count} }"
    end
    puts "###########inconsistency sessions###############"
    @inconsistency_sessions.each do |version, count|
      unless @states_counter[version].nil?
        puts "#{version} ## #{count} ## #{count * 1.0 / @states_counter[version]["frontporch"]}"
      end
    end
    @return_uids.each do |version, uidset|
      if uidset.length > 100
        return_uid_output = File.new("return_uid#{version}.output", "w")
        uidset.each do |uid|
          return_uid_output.puts uid
        end
      end
    end

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
        "Conversion"]
      @states_counter.each do |key, state_counter|
        # ==> Head Part

        # ==> Value Part
        csv_data << [
          key,
          state_counter["frontporch"],
          state_counter["signup_start"],
          state_counter["email"],
          state_counter["step1"],
          state_counter["card"],
          state_counter["conversion"],
          format("%.2f", state_counter["conversion"] * 100.0 / state_counter["frontporch"])
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


