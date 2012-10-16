require './analyze_job'
require 'date'
class ViewedPageCountAnalyzeJob < AnalyzeJob
  
  def initialize
    super
    @visits = {}
    @page_view = {}
    @output_filename = "viewed_page"
    @result = ""
    @total_visits = 0
  end
  # ==> methods derivation Has to implement
  def analyze_session session
    visit_time = DateTime.parse(session[0]["visit_time"])
    mark_landing = false
    mark_conversion = false

    viewed_pages = Set.new

    version = ""
    
    analyze session do |action|
      if !mark_landing and action["_type"] == "page_load"
        @total_visits += 1
        if front_porch? action
          mark_landing = true
          version = extract_version action["pageurl"]
        end
      end
      
      if action["_type"] == "page_load"
        if conversion? action
          mark_conversion = true
        else
          pageurl = action["pageurl"]
          pageurl = pageurl.split("?")[0]
          viewed_pages.add(pageurl)
        end
      end
    end

    unless mark_landing
      return
    end
    

    viewed_pages.each do |viewed_page|
      @page_view[version] ||= {}
      @page_view[version][viewed_page] ||= 0
      @page_view[version][viewed_page] += 1
    end


    @visits[version] ||= 0 
    @visits[version] += 1

  end

  def output_format
    puts "page_view total visits: #{@total_visits}"
  end

  def output_csv_format
    @csv = CSV.generate do |csv_data|
      csv_data << [
        "Version",
        "View Page",
        "Visits"
      ]
      @page_view.each do |version, visit_page_data|
        visit_page_data.each do |visit_page, visit_count|
          if (visit_count < 100)
            next
          end
          visit_rate = visit_count * 1.0 / @visits[version]

          csv_data << [
            version.to_s,
            visit_page.to_s,
            visit_count.to_s,
            visit_rate.to_s
          ]
        end
      end
    end
  end
end


