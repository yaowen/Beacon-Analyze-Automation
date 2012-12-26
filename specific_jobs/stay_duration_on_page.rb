require './analyze_job'
require 'set'
require 'date'
class StayDurationOnPage < AnalyzeJob
  
  def initialize
    super
    @states_counter = {}
    @total_visitors = {}
    @output_filename = "stay_time_distribute"
    @result = ""
  end
  # ==> methods derivation Has to implement

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
    mark_watch_video = false
    version = ""
    during = -1
    start_time = nil
    end_time = nil
    analyze session do |action|
      if !mark_landing and action["_type"] == "page_load"
        if front_porch? action
          version = extract_version action["pageurl"]
          start_time = DateTime.parse(action["visit_time"])
          mark_landing = true
        end
      elsif mark_landing and action["_type"] == "page_load"
        if signup_start? action
          end_time = DateTime.parse(action["visit_time"])
          during = ((end_time - start_time) * 24 * 60 * 60).to_int
          break;
        end
      end

      if action["_type"] == "slider_action"
        if action["pageurl"] =~ /^http:\/\/www2\.hulu\.jp\/?(\?.*)?$/
          mark_watch_video = true
        end
      end
    end

    watch_video_tag = mark_watch_video ? "w" : "nw"

    need_versions = ["origin", "201208073", "201208144", "201208222", "201208312"]
    unless need_versions.include? version
      return
    end

    @total_visitors[version] ||= {}
    @total_visitors[version][watch_video_tag] ||= 0
    if (during > 0 && during <= 6000) 
      @total_visitors[version][watch_video_tag] += 1
      if @states_counter[version].nil?
        @states_counter[version] = {}
        @states_counter[version]["w"] = {}
        @states_counter[version]["nw"] = {}
        @states_counter[version].each do |watch_tag, watch_tag_counter|
          6000.times do |i|
            watch_tag_counter[i] = 0
          end
        end
      end
      @states_counter[version][watch_video_tag][during] += 1
    elsif during > 0
      puts during
    end
  end

  def output_format
  end

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      @states_counter.each do |version, watch_tag_counter|
        watch_tag_counter.each do |watch_tag, distribute|
          total_time = 0
          total_users = 0
          temp_users = 0
          temp_users_2 = 0
          6000.times do |i|
            total_time = total_time + (i+1) * distribute[i]
            total_users = total_users + distribute[i]
            temp_users = temp_users + distribute[i]
            temp_users_2 = temp_users_2 + distribute[i] if i < 360
            if( i % 10 == 9 && i < 360) 
              csv_data << [temp_users]
              temp_users = 0
            end
            #if( i < 20) 
            #  csv_data << [
            #    version,
            #    watch_tag,
            #    i,
            #    distribute[i]
            #  ]
            #end
          end
          csv_data << [@total_visitors[version][watch_tag] - temp_users_2]
          csv_data << [version, watch_tag, "avg", total_time * 1.0 / total_users, temp_users_2 * 1.0 / @total_visitors[version][watch_tag]]
        end
      end
    end
  end

  def output_email_format
  end
end


