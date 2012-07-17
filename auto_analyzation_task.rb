#automating the whole regular analyze job flow
require './file_exist_checker'
require './job_config'

STORE_PATH="/mnt/data/yaowen.zheng"
USERJOB="/mnt/garfield_dump/userjobs"
RUBY_CMD="/home/deploy/.rvm/rubies/ruby-1.9.3-p0/bin/ruby"

#STORE_PATH="/Users/hulu/Documents/MyInfo/BeaconData"
#USERJOB="/Volumes/datastore/userjobs"
#RUBY_CMD="ruby"

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

#==> path settings


def clean_up dir_path
  if( File.exist? dir_path)
    #in case there aren't any file in the path which will cause problem
    system_with_command_print("touch #{dir_path}/for_remove")
    system_with_command_print("rm #{dir_path}/*")
  end
end

$cmd_params = Hash.new

# ==> Analyze Command Parameter
ARGV.each do |command_param|
  key, value = command_param.split("=")
  $cmd_params[key] = value
end

$start_date_str = $cmd_params["startdate"] || (DateTime.now - 1).strftime("%Y-%m-%d")
$end_date_str = $cmd_params["enddate"] || $start_date_str
fetchdata = $cmd_params["fetchdata"] || "true"
analyzedata = $cmd_params["analyzedata"] || "true"

def gen_date_str
  start_date = DateTime.parse($start_date_str)
  end_date = DateTime.parse($end_date_str)
  #date string for all the files
  if( start_date == end_date )
    date_str = start_date.strftime("%Y%m%d")
  else
    date_str = start_date.strftime("%Y%m%d") + "-" + end_date.strftime("%Y%m%d")
  end

end


def fetch_data
  raw_beacon_root_directory = "#{STORE_PATH}/beacon_raw_data"
  json_root_directory = "#{STORE_PATH}/json_mid_file"

  validate_directory(raw_beacon_root_directory)
  validate_directory(json_root_directory)
  validate_directory(json_root_directory + "/session")
  validate_directory(json_root_directory + "/visitors")

  start_date = DateTime.parse($start_date_str)
  end_date = DateTime.parse($end_date_str)
  #==Fetch Data Part
  jobids = []
  #post data

  #init job_config class
  job_config = JobConfig.new
  job_config.load("./job.yml")

  def parse_jobids jobid_str
    m_jobids = jobid_str.split("#")
  end


  if $cmd_params["jobids"].nil?
    #New Visiter Page View
    jobids = job_config.generate_jobs(start_date, end_date)
  else
    jobids = parse_jobids($cmd_params["jobids"])
  end

  #mount the smb file system
  #puts system("sudo mount -a")

  puts "jobids: #{jobids}"

  #TODO Delete the mock
  #== mock
  #jobids = ["4119", "4120"]
  #
  date_str = gen_date_str


  #check file exist
  local_store_beacon_directory = "#{raw_beacon_root_directory}/#{date_str}"
  clean_up(local_store_beacon_directory)
  validate_directory(local_store_beacon_directory)
  jobids.each do |jobid|
    job_file_path = "#{USERJOB}/#{jobid}.tsv.gz"
    job_store_file_name = "#{date_str}_#{jobid}.tsv.gz"

    local_store_beacon_file_path = "#{local_store_beacon_directory}/#{job_store_file_name}"


    try_limit = 100
    try_limit.times do |i|
      begin
        when_file_exist job_file_path do
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

  system_with_command_print("#{RUBY_CMD} beacon_divider.rb input=#{raw_beacon_root_directory}/#{date_str} output=#{json_root_directory}")
end

def gen_start_time start_date_str
    start_date = DateTime.parse(start_date_str);
  if (start_date_str.split(" ").length == 1)
    return start_date.strftime("%Y-%m-%d 00:00:00");
  else
    return start_date.strftime("%Y-%m-%d %M:%H:%S");
  end
end

def gen_end_time end_date_str
  end_date = DateTime.parse(end_date_str);
  if (end_date_str.split(" ").length == 1)
    return end_date.strftime("%Y-%m-%d 23:59:59");
  else
    return end_date.strftime("%Y-%m-%d %M:%H:%S");
  end
end

def analyze_data
  json_root_directory = "#{STORE_PATH}/json_mid_file"
  date_str = gen_date_str
  metrics_root_directory = "#{STORE_PATH}/metrics"
  validate_directory(metrics_root_directory)
  #start analyzing jobs
  validate_directory("#{metrics_root_directory}/#{date_str}_session")
  validate_directory("#{metrics_root_directory}/#{date_str}_visitor")


  start_date_str = gen_start_time($start_date_str)
  end_date_str = gen_end_time($end_date_str)
  system_with_command_print("#{RUBY_CMD} analyze_from_json.rb input=#{json_root_directory}/session output=#{metrics_root_directory}/#{date_str}_session startdate=\"#{start_date_str}\" enddate=\"#{end_date_str}\"")
  system_with_command_print("#{RUBY_CMD} analyze_from_json.rb input=#{json_root_directory}/visitors output=#{metrics_root_directory}/#{date_str}_visitor startdate=\"#{start_date_str}\" enddate=\"#{end_date_str}\"")
end

if "true" == fetchdata
  fetch_data
end

if "true" == analyzedata
  analyze_data
end







