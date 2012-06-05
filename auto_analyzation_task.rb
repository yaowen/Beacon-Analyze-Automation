#automating the whole regular analyze job flow
require './post_beacon_mission.rb'
require './file_exist_checker.rb'

#STORE_PATH="/home/deploy/yaowen.zheng"
#USERJOB="/mnt/garfield_dump/userjobs"

STORE_PATH="/Users/hulu/Documents/MyInfo/BeaconData"
USERJOB="/Volumes/datastore/userjobs"

start_date = DateTime.now - 1
end_date = start_date

jobids = []
#post data
jobids << post_beacon_data( 
                 :page_regex => ".*sitetracking/pageload.*userid=0.*", 
                 :job_title => "site japan fp",
                 :start_date => start_date, 
                 :end_date => end_date)
jobids << post_beacon_data( 
                 :page_regex => ".*sitetracking/pageload.*userid=[1-9][0-9]*.*signup_complete.*",
                 :job_title => "site japan convert", 
                 :start_date => start_date,
                 :end_date => end_date)
exit

#mount the smb file system
#puts system("sudo mount -a")

#check file exist
jobids.each do |jobid|
  job_file_path = "#{USERJOB}/#{jobid}.tsv.gz"
  when_file_exist job_file_path do
    puts system("cp #{USERJOB}/#{jobid}.tsv.gz #{STORE_PATH}/#{start_date}/#{job_store_file_name}")
  end
end

#translate beacon into json and aggregate according to session
puts system("/ruby beacon_to_json.rb input=#{STORE_PATH}/#{start_date} output=#{STORE_PATH}/json_mid_file/#{start_date}.json")

#start analyzing jobs


