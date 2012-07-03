require './analyze_job'
require 'set'
class CampaignSignupFunnelAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @states_counter = {}
    @output_filename = "signup_funnel"
    @result = ""
    @total = 0
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
    @states_counter.each do |key, state_cmp_counter|
      state_cmp_counter.each do |cmp, state_counter|
        marks.each do |mark|
          state_counter[mark] ||= 0
        end
      end
    end
  end

  def analyze_session session
    marks = Set.new
    mark_landing = false
    version = ""
    cmp = ""
    analyze session do |action|
      if !mark_landing && action["_type"] == "page_load"
        if front_porch? action
          version = extract_version action["pageurl"]
          cmp = extract_campaign action["pageurl"]
          mark_landing = true
        end
      end
      if action["_type"] == "signup_action"
        if action["field"] == "email"
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
    @states_counter[version][cmp] ||= {}
    marks.each do |mark|
      add_one @states_counter[version][cmp], mark
    end
    formalize
  end

  def output_format

  end

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      csv_data << [
        "Version",
        "Campaign",
        "Landing", 
        "Signup Start", 
        "Input Email", 
        "Step1 Complete",
        "Input CC", 
        "Conversion"]
      @states_counter.each do |version, state_cmp_counter|
        # ==> Head Part
        state_cmp_counter.each do |cmp, state_counter|
        # ==> Value Part
          csv_data << [
            version,
            cmp,
            state_counter["frontporch"],
            state_counter["signup_start"],
            state_counter["email"],
            state_counter["step1"],
            state_counter["card"],
            state_counter["conversion"]
          ]
        end
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


