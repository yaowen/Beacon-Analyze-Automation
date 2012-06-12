require './analyze_job'
require 'set'
class SignupFunnelAnalyzeJob < AnalyzeJob
  
  def initialize
    @states_counter = Hash.new
    @output_filename = "signup_funnel.output"
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

  def analyze_session session
    marks = Set.new
    unless front_porch? session[0]
      return
    end
    analyze session do |action|
      if action["_type"] == "SignUpAction"
        if action["field"] == "email"
          marks.add "email"
        elsif action["field"] == "card"
          marks.add "card"
        end
      elsif action["_type"] == "PageViewAction"
        if front_porch? action
          marks.add "frontporch"
        elsif conversion? action
          marks.add "conversion"
        elsif signup_start? action
          marks.add "signup_start"
        end
      end
    end

    marks.each do |mark|
      add_one @states_counter, mark
    end
  end

  def output_format
    @result += "Landing: #{@states_counter["frontporch"]}\n"
    @result += "Signup Start: #{@states_counter["signup_start"]}\n"
    @result += "Input Email: #{@states_counter["email"]}\n"
    @result += "Input CC: #{@states_counter["card"]}\n"
    @result += "Conversion: #{@states_counter["conversion"]}\n"
  end
end


