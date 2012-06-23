require 'json'
require './analyze_utils'
require './analyze_jobs/goal_numbers_count'
require './analyze_jobs/page_view_count'
require './analyze_jobs/visit_number_count'
require './analyze_jobs/watched_view_analyze'
require './analyze_jobs/os_analyze'
require './analyze_jobs/video_watch_analyze'
require './analyze_jobs/signup_funnel_analyze'
require './analyze_jobs/landing_normal_state_analyze'
require './analyze_jobs/conversion_on_landing'
require './analyze_jobs/preview_watch_analyze'

MAX_INTERVAL = 100

#==> reading from specific files
$cmd_params = Hash.new

# ==> Analyze Command Parameter
ARGV.each do |command_param|
  key, value = command_param.split("=")
  $cmd_params[key] = value
end

def validate_param key
  puts $cmd_params
  while $cmd_params[key].nil?
    puts "Missing #{key}, Please enter: "
    value = gets
    unless value.nil? || value == '\n'
      $cmd_params[key] = value.split(/\n/)[0]
      break
    end
  end
end

validate_param "input"
validate_param "output"

start_date_str = $cmd_params["startdate"]
end_date_str = $cmd_params["enddate"]
input_path = $cmd_params["input"]
output_path = $cmd_params["output"]


#==> analyze job list
$job_queue = [
  #TestAnalyzeJob.new
  #GoalNumberCountAnalyzeJob.new,
  #WatchViewCountAnalyzeJob.new,
  #VisitNumberCountAnalyzeJob.new,
  #PageViewCountAnalyzeJob.new,
  #OSAnalyzeJob.new,
  VideoWatchAnalyzeJob.new,
  #PreviewWatchAnalyzeJob.new,
  SignupFunnelAnalyzeJob.new
  #LandingNormalStateAnalyzeJob.new
  #ConversionOnLandingCountAnalyzeJob.new
]

def analyze_json_file file
  linecount = 0
  lines = IO.readlines(file)
  lines.each do |line|
    linecount += 1
    print("#{linecount}\r") if linecount % 1000 == 0
    user_pattern_actions = JSON.parse(line)
    #analyze jobs
    $job_queue.each do |analyze_job|
      analyze_job.analyze_session user_pattern_actions
    end
  end
end

MAX_INTERVAL.times do |i|
  start_date = DateTime.parse(start_date_str)
  end_date = DateTime.parse(end_date_str)
  cur_date = start_date + i
  if(cur_date > end_date)
    break
  end
  cur_date_str = cur_date.strftime("%Y%m%d")
  puts cur_date_str
  analyze_json_file("#{input_path}/#{cur_date_str}.json")
end

$job_queue.each do |analyze_job|
  analyze_job.output_result output_path
  puts output_path
  analyze_job.before_exit
end
exit
