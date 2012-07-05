require './analyze_job'
class PageViewCountAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @pv_count = 0
    @pv_count_details = {}
    @output_filename = "page_view_number"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    analyze session do |action|
      if action["_type"] == "page_load"
        pageurl = action["pageurl"]
        if !(pageurl =~ /^http\:\/\/www2\.hulu\.jp\/(\?.*)?$/).nil?
          @pv_count += 1
          @pv_count_details[pageurl] ||= 0
          @pv_count_details[pageurl] += 1
        end
      end
    end
  end

  def output_format
    total_count = 0
    @result = "#{@pv_count}\n"
    line_count = 0
    @result += "#{@pv_count_details.length}\n"
    @pv_count_details.each do |pageurl, count|
      total_count += count
      @result += "#{line_count} #{pageurl} #{count}\n"
      line_count += 1
      print ("output: #{line_count} \r") if line_count % 1000 == 0
      flush
    end
    @result += "Total Count: #{total_count}\n"
  end
end


