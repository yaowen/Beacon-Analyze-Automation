require './analyze_job'
class ConversionOnLandingCountAnalyzeJob < AnalyzeJob
  
  def initialize
    @conversion_landing_counter = Hash.new
    @landing_counter = Hash.new
    @output_filename = "conversion_on_landing.output"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    url = session[0]["pageurl"]
    if url =~ /www2.hulu.jp\/watch\//
      return
    end
    url = remove_parameter url
    @conversion_landing_counter[url] ||= 0
    @landing_counter[url] ||= 0
    @landing_counter[url] += 1
    analyze session do |action|
      if conversion? action
        @conversion_landing_counter[url] += 1
        return
      end
    end
  end

  def output_format
    sort_counter = @conversion_landing_counter.sort do |a, b|
      (a[1] * 1.0 / @landing_counter[a[0]]) <=> (b[1] * 1.0 / @landing_counter[b[0]])
    end
    sort_counter.each do |landing_url, count|
      if count < 10
        next
      end
      @result += "#{landing_url}  #{count}  #{count * 100.0 / @landing_counter[landing_url]}%\n"
    end
  end

  def remove_parameter url
    return url.split("?")[0]
  end
end


