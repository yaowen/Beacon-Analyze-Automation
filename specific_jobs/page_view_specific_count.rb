require './analyze_job'
class PageViewSpecificCountAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @pv_count = 0
    @pv_count_details = {}
    @output_filename = "page_view_number"
    @result = ""
  end
  # ==> methods derivation Has to implement
  #
  def filter_param url, param
    param_part = url.scan(/(\?|&)(#{param}=.*?)(&|$)/)
    if param_part.length == 0
      return url
    end
    param_part = param_part[0][1]
    index = url.index(param_part)
    param_part = url[index-1] + param_part
    url = url.gsub(param_part, "")
    if url.length > index - 1
      url[index-1] = '?'
    end
    return url
  end
  def analyze_session session
    analyze session do |action|
      if action["_type"] == "page_load"
        pageurl = action["pageurl"]
        sitesessionid = action["sitesessionid"]
        if !(pageurl =~ /^http\:\/\/www2\.hulu\.jp\/(\?.*)?$/).nil?
          filter_params = ["utoken", "token", "info_id", "wapr", "docomo_code", "locale", "f2", "fb_xd_fragment"]
          filter_params.each do |filter_parameter|
            pageurl = filter_param pageurl, filter_parameter
          end
          @pv_count += 1
          @pv_count_details[sitesessionid] ||= {}
          @pv_count_details[sitesessionid][pageurl] ||= {}
          @pv_count_details[sitesessionid][pageurl]["count"] ||= 0
          @pv_count_details[sitesessionid][pageurl]["visit_time"] = action["visit_time"].split(" ")[0]
          @pv_count_details[sitesessionid][pageurl]["os"] = action["os"].sub(" ", "")
          @pv_count_details[sitesessionid][pageurl]["client"] = action["client"].sub(" ", "")
        end
      end
    end
  end

  def output_format
    total_count = 0
    @result = "#{@pv_count}\n"
    line_count = 0
    @result += "#{@pv_count_details.length}\n"
    @pv_count_details.each do |sitesessionid, page_detail|
      page_detail.each do |pageurl, detail|
        total_count += detail["count"]
        @result += "#{line_count} #{sitesessionid} #{pageurl} #{detail["count"]} #{detail["visit_time"]} #{detail["os"]} #{detail["client"]}\n"
        line_count += 1
        print ("output: #{line_count} \r") if line_count % 1000 == 0
        flush
      end
    end
    @result += "Total Count: #{total_count}\n"
  end
end


