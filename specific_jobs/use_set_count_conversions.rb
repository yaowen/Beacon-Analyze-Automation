require './analyze_job'
class SetCountConversionJob < AnalyzeJob
  
  def initialize
    super
    @version = "origin"
    @visit_count = 0
    @conversion_count = 0
    @visit_or_conversion_count = 0
    @output_filename = "visitor_id_list"
    @only_conversion = 0
    @session_detail_file = File.new("session_detail.output", "w")
  end
  # ==> methods derivation Has to implement
  #
  def analyze_session session
    mark_landing = false
    mark_conversion = false
    analyze session do |action| 
      if !mark_landing and action["_type"] == "page_load"
        if front_porch? action
          version = extract_version action["pageurl"]
          if(version == @version)
            mark_landing = true
          end
        end
      end
      if conversion? action
        mark_conversion = true
      end
    end
    if mark_landing
      @visit_count ||= 0
      @visit_count += 1
    end
    if mark_conversion
      @conversion_count ||= 0
      @conversion_count += 1
    end
    if (!mark_landing && mark_conversion)
      @only_conversion += 1
    end
    
    if (mark_landing || mark_conversion)
      #puts pretty_session_form(session)
      @visit_or_conversion_count += 1
    end
  end

  def output_format
    visit_or_conversion_num = @visit_or_conversion_count
    conversion = @conversion_count - @only_conversion
    puts "###########"
    puts "#{@version}: #{@visit_count} #{visit_or_conversion_num} #{conversion} #{@only_conversion}"
  end
end


