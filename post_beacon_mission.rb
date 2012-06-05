require 'net/http'
require 'cgi'
require 'date'

def generate_post_data res, option = {}
  authenticity_token = res.body.scan(/name="authenticity_token.*value=\"(.*)\"/)[0][0]
  start_date = option[:start_date]
  end_date = option[:end_date]
  page_regex = option[:page_regex]
  job_title = option[:job_title]

  data_common = {
    "authenticity_token" => authenticity_token,
    "userjob[email]" => "yaowen.zheng@hulu.com",
    "userjob[start_time(1i)]" => start_date.year.to_s,
    "userjob[start_time(2i)]" => start_date.month.to_s,
    "userjob[start_time(3i)]" => start_date.day.to_s,
    "userjob[end_time(1i)]" => end_date.year.to_s,
    "userjob[end_time(2i)]" => end_date.month.to_s,
    "userjob[end_time(3i)]" => end_date.day.to_s,
    "userjob[start_ip]" => "",
    "userjob[end_ip]" => "",
    "userjob[regionid]" => "2",
    "userjob[inputfiletypes]" => "sitetracking",
    "userjob[required_fields]" => "",
    "userjob[additional_fields]" => "computerguid sitesessionid pageurl client os pvic pvis vc time hour",
    "userjob[output_format]" => "tsv format",
    "commit" => "Create"
  }

  date_str = "#{start_date.month.to_s}.#{start_date.day.to_s} ~ #{end_date.month.to_s}.#{end_date.day.to_s}"
  job_title = "#{job_title} #{date_str}"

  data_common["userjob[regex]"] = page_regex
  data_common["userjob[userjobname]"] = job_title

  return data_common
end

def query_str(data_map)
  kv_pairs = []
  data_map.each do |key, value|
    kv_pairs << "#{CGI::escape key}=#{CGI::escape value}"
  end
  return kv_pairs.join("&")
end

def post_beacon_data options = {}
  #==> initialize parameters
  job_title = options[:job_title]
  start_date = options[:start_date]
  end_date = options[:end_date]
  page_regex = options[:page_regex]

  #==> send a get request to get the authenticity_token and cookie
  uri = URI('http://10.16.80.30:8000/userjobs/new')
  res = Net::HTTP.get_response(uri)
  authenticity_token = res.body.scan(/name="authenticity_token.*value=\"(.*)\"/)[0][0]
  cookie = res.response['set-cookie'].split(";")[0]

  #==> send post request to create a new job
  headers = { "Cookie" => cookie }
  puts cookie

  data = generate_post_data(res, 
                 :page_regex => page_regex,
                 :start_date => start_date,
                 :end_date => end_date,
                 :job_title => job_title)
  #datas << gen_data(:site, res)
  #datas << gen_data(:signup_complete, res)

  #==> rewrite the data into a post legal data
  data = query_str(data)
  puts data

  h = Net::HTTP.new('10.16.80.30', 8000)
  res = h.post("/userjobs/create", data, headers)
  puts res.body
  puts res.code
  puts res.message

  uri = URI('http://10.16.80.30:8000/userjobs')
  res = Net::HTTP.get_response(uri)
  #puts res.body.gsub(/\s+/, " ").strip
  data = res.body.gsub(/\s+/, " ").strip
  #puts data
  jobid = data.scan(/<td rowspan=\"2\">(.*?)<\/td> <td colspan=\"2\"> <a href=\"http\:\/\/10\.16\.80\.30\:50030\/jobdetails\.jsp.*?>.*?#{job_title}.*?<\/a> /)[0][0]
  puts "jobid: #{jobid}"
  return jobid
end


