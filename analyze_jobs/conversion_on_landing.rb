require './analyze_job'
class ConversionOnLandingCountAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @total_landings = 0
    @total_conversions = 0
    @conversion_landing_counter = Hash.new
    @landing_counter = Hash.new
    @output_filename = "conversion_on_landing"
    @result = ""
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    @total_landings += 1
    unless session[0]["_type"] == "page_load"
      return
    end
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
        @total_conversions += 1
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

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      total_conversion_rate = @total_conversions * 1.0 / @total_landings
      csv_data << [
        "Total Conversion Rate",
        total_conversion_rate.to_s
      ]
      csv_data << [
        "Landing Page Name",
        "Landing Rate",
        "Landing Count",
        "Conversion",
        "Conversion Rate",
        "Improvement"
      ]

      @landing_counter.each do |landing_page, landing_count|
        if landing_count < 50
          next
        end
        landing_rate = landing_count * 1.0 / @total_landings
        conversion = @conversion_landing_counter[landing_page]
        conversion_rate = conversion * 1.0 / landing_count
        improvement = conversion_rate * 1.0 / total_conversion_rate - 1
        csv_data << [
          landing_page,
          landing_rate,
          landing_count,
          conversion,
          conversion_rate,
          improvement
        ]
      end
    end
  end

  def output_email_format
    @email_report = ""
  end

  def remove_parameter url
    return url.split("?")[0]
  end
end


