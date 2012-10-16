require './analyze_job'
require 'set'
class SignupFunnelAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @states_counter = Hash.new
    @output_filename = "signup_funnel"
    @result = ""
    @total = 0
    @total_visits = 0
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
    version = ""
    analyze session do |action|
      if !mark_landing and action["_type"] == "page_load"
        @total_visits += 1
        if front_porch?(action)
          version = extract_version action["pageurl"]
          mark_landing = true
        end
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
        if front_porch? action
          marks.add "frontporch"
        elsif conversion? action
          marks.add "conversion"
        elsif signup_start? action
          marks.add "signup_start"
        end
      end
    end

    unless mark_landing
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
        puts key
	fps.each do |fp|
          need_mark = false if state_counter[fp] < 10
          puts need_mark
        end
        next unless need_mark
       

        # ==> Value Part
        csv_data << [
          key,
          state_counter["frontporch"],
          state_counter["signup_start"],
          state_counter["email"],
          state_counter["step1"],
          state_counter["card"],
          state_counter["conversion"],
          format("%.2f%", state_counter["signup_start"] * 100.0 / state_counter["frontporch"]),
          format("%.2f%", state_counter["email"] * 100.0 / state_counter["signup_start"]),
          format("%.2f%", state_counter["step1"] * 100.0 / state_counter["email"]),
          format("%.2f%", state_counter["card"] * 100.0 / state_counter["step1"]),
          format("%.2f%", state_counter["conversion"] * 100.0 / state_counter["card"]),
 
          format("%.2f%", state_counter["step1"] * 100.0 / state_counter["frontporch"]),
          format("%.2f%", state_counter["conversion"] * 100.0 / state_counter["frontporch"])
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


