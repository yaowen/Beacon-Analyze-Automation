#automating the whole regular analyze job flow
require './post_beacon_mission.rb'
require './file_exist_checker.rb'

#STORE_PATH="/home/deploy/yaowen.zheng"
#USERJOB="/mnt/garfield_dump/userjobs"
#RUBY_CMD="opt/ruby-1.9.2-p136/bin/ruby"

STORE_PATH="/Users/hulu/Documents/MyInfo/BeaconData"
USERJOB="/Volumes/datastore/userjobs"
RUBY_CMD="ruby"

def system_with_command_print cmd
  puts cmd
  result = system(cmd)
  puts "result => #{result}"
  if( result == false )
    raise 
  end
end

#validate whether directory exist
#if not, create one
def validate_directory dir_path
  unless( File.exist? dir_path )
    system_with_command_print("mkdir #{dir_path}")
  end
end

$cmd_params = Hash.new

# ==> Analyze Command Parameter
ARGV.each do |command_param|
  key, value = command_param.split("=")
  $cmd_params[key] = value
end

start_date = !$cmd_params["startdate"].nil? ? DateTime.parse($cmd_params["startdate"]) : DateTime.now - 1
end_date = !$cmd_params["enddate"].nil? ? DateTime.parse($cmd_params["enddate"]) : start_date
use_old_job = $cmd_params["useoldjob"].nil? ? false : true

jobids = []
#post data

def parse_jobids jobid_str
  m_jobids = jobid_str.split("#")
end


unless use_old_job
  #New Visiter Page View
  jobids << post_beacon_data( 
                   :page_regex => ".*sitetracking/pageload.*userid=0.*", 
                   :job_title => "site japan fp",
                   :start_date => start_date, 
                   :end_date => end_date,
                   :input_file_types => "sitetracking",
                   :additional_fields => "computerguid sitesessionid pageurl client os pvic pvis vc time")

  #Conversion
  jobids << post_beacon_data( 
                   :page_regex => ".*sitetracking/pageload.*userid=[1-9][0-9]*.*signup_complete.*",
                   :job_title => "site japan convert", 
                   :start_date => start_date,
                   :end_date => end_date,
                   :input_file_types => "sitetracking",
                   :additional_fields => "computerguid sitesessionid pageurl client os pvic pvis vc time page_load")
  #Play Video
  jobids << post_beacon_data( 
                   :page_regex => ".*playback/start\?.*userid=0.*",
                   :job_title => "site japan video play", 
                   :start_date => start_date,
                   :end_date => end_date,
                   :input_file_types => "playback",
                   :additional_fields => "computerguid sitesessionid contentid packageid client os time play_action")
  #Signup Event
  jobids << post_beacon_data( 
                   :page_regex => ".*sitetracking/signupevent\?.*userid=0.*",
                   :job_title => "site japan signup event", 
                   :start_date => start_date,
                   :end_date => end_date,
                   :input_file_types => "sitetracking",
                   :additional_fields => "computerguid sitesessionid pageurl field client os time signup_action")
  #Slider Event for homepage preview
  jobids << post_beacon_data( 
                   :page_regex => ".*sidetracking/slidertracking\?.*userid=0.*",
                   :job_title => "site japan slidertrack event", 
                   :start_date => start_date,
                   :end_date => end_date,
                   :input_file_types => "sitetracking",
                   :additional_fields => "computerguid sitesessionid pageurl contentid client os time slider_action")
                   
else
  jobids = parse_jobids($cmd_params["jobids"])
end

#mount the smb file system
#puts system("sudo mount -a")

puts "jobids: #{jobids}"

#TODO Delete the mock
#== mock
#jobids = ["4119", "4120"]

#date string for all the files
if( start_date == end_date )
  date_str = start_date.strftime("%Y%m%d")
else
  date_str = start_date.strftime("%Y%m%d") + "-" + end_date.strftime("%Y%m%d")
end

#check file exist
jobids.each do |jobid|
  job_file_path = "#{USERJOB}/#{jobid}.tsv.gz"
  job_store_file_name = "#{date_str}_#{jobid}.tsv.gz"

  local_store_beacon_directory = "#{STORE_PATH}/#{date_str}"
  local_store_beacon_file_path = "#{local_store_beacon_directory}/#{job_store_file_name}"
  try_limit = 100
  try_limit.times do |i|
    begin
      when_file_exist job_file_path do
        validate_directory(local_store_beacon_directory)
        #copy the generated tsv.gz file into local_store_beacon_directory
        system_with_command_print("cp #{USERJOB}/#{jobid}.tsv.gz #{local_store_beacon_file_path}")
        #unzip the *.tsv.gz file
        system_with_command_print("gzip -df #{local_store_beacon_file_path}")
      end
    rescue
      #if error occurs, try one more time
      sleep(60)
      next
    end
    break
  end
end


#translate beacon into json and aggregate according to session
validate_directory("#{STORE_PATH}/json_mid_file")

system_with_command_print("ruby beacon_to_json.rb input=#{STORE_PATH}/#{date_str} output=#{STORE_PATH}/json_mid_file/#{date_str}.json")

#start analyzing jobs
validate_directory("#{STORE_PATH}/metrics")
validate_directory("#{STORE_PATH}/metrics/#{date_str}_session")
validate_directory("#{STORE_PATH}/metrics/#{date_str}_visitor")
system_with_command_print("#{RUBY_CMD} analyze_from_json.rb #{STORE_PATH}/json_mid_file/#{date_str}.json_session #{STORE_PATH}/metrics/#{date_str}_session")
system_with_command_print("#{RUBY_CMD} analyze_from_json.rb #{STORE_PATH}/json_mid_file/#{date_str}.json_visitors #{STORE_PATH}/metrics/#{date_str}_visitor")



