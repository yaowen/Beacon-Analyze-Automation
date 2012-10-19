require 'json'
require './analyze_utils'
require './analyze_jobs/goal_numbers_count'
require './analyze_jobs/page_view_count'
require './analyze_jobs/visit_number_count'
require './analyze_jobs/watched_view_analyze'
require './analyze_jobs/os_analyze'
require './analyze_jobs/video_watch_analyze'
require './analyze_jobs/video_watch_regular_analyze'
require './analyze_jobs/signup_funnel_analyze'
require './analyze_jobs/landing_normal_state_analyze'
require './analyze_jobs/conversion_on_landing'
require './analyze_jobs/preview_watch_analyze'
require './analyze_jobs/signup_funnel_analyze_with_version_check'
require './analyze_jobs/viewed_page_analyze'

require './specific_jobs/preview_watch_analyze'
require './specific_jobs/free_episode_and_walkthrough_viewed'
require './specific_jobs/load_to_start_duration'
require './specific_jobs/easy_goal_count'
require './specific_jobs/landing_fp_view_count'
require './specific_jobs/list_all_visitors'
require './specific_jobs/use_set_count_conversions'
require './specific_jobs/signup_funnel_analyze_for_signup'
require './specific_jobs/stay_duration_on_page'

require './filters/action/time_filter'
require './filters/session/time_filter'

require './daily_reports/goal_numbers_count'


MAX_INTERVAL = 100

#==> reading from specific files
$cmd_params = Hash.new

# ==> Analyze Command Parameter
ARGV.each do |command_param|
  key, value = command_param.split("=")
  $cmd_params[key] = value
end

def validate_param key
  while $cmd_params[key].nil?
    puts $cmd_params
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

puts "command parameters: #{$cmd_params}"


#==> analyze job list
$job_queue = [
  #TestAnalyzeJob.new
  #GoalNumberCountAnalyzeJob.new,
  #WatchViewCountAnalyzeJob.new,
  #VisitNumberCountAnalyzeJob.new,
  #PageViewCountAnalyzeJob.new
  #OSAnalyzeJob.new,
  #VideoWatchAnalyzeJob.new
  #VideoWatchRegularAnalyzeJob.new
  #PreviewWatchAnalyzeJob.new,
  #ViewedPageCountAnalyzeJob.new,
  #SignupFunnelAnalyzeJob.new
  #LandingNormalStateAnalyzeJob.new
  #ConversionOnLandingCountAnalyzeJob.new
  #PreviewWatchSpecificAnalyzeJob.new
  #PageViewSpecificCountAnalyzeJob.new
  #PreviewWatch_v2_SpecificAnalyzeJob.new
  #LoadToPlayDurationAnalyzeJob.new
  #SignupFunnelWithVersionCheckAnalyzeJob.new
  #ListAllVisitorsJob.new
  #EasyGoalCount.new
  #SetCountConversionJob.new
  #SignupFunnelAnalyzeJobForSignup.new
  StayDurationOnPage.new
]

#==> report list
$report_queue = [
  #GoalNumberCountReport
]

$common_filters = {
  :timefilter => TimeSessionFilter.new
}

def filter_init params={}
  #==> time filter
  unless $common_filters[:timefilter].nil?
    $common_filters[:timefilter].start_time = params[:start_date]
    $common_filters[:timefilter].end_time = params[:end_date]
  end
end

def init_report_jobs report_date
  report_job_queue = []
  puts report_date
  $report_queue.each do |daily_report_job_class|
    puts daily_report_job_class
    t_report_job = daily_report_job_class.new(report_date)
    report_job_queue << t_report_job
  end
  return report_job_queue
end

#each file is aggregate by date
def analyze_json_file file, cur_date
  report_job_queue = init_report_jobs(cur_date)

  linecount = 0
  lines = IO.readlines(file)
  puts "analyzing file: #{file}"
  lines.each do |line|
    linecount += 1
    print("analyzeing line: #{linecount}\r") if linecount % 1000 == 0
    user_pattern_actions = JSON.parse(line)
    #analyze jobs
    $job_queue.each do |analyze_job|
      analyze_job.analyze_session_entry user_pattern_actions
    end
    report_job_queue.each do |daily_report_job|
      daily_report_job.analyze_session_entry user_pattern_actions
    end
  end
  puts

  report_job_queue.each do |daily_report_job|
    daily_report_job.output_result
  end
end

#==> Initialize Filters
filter_params ||= {}
filter_params[:start_date] = start_date_str
filter_params[:end_date] = end_date_str
filter_init filter_params

#==> Initializing Jobqueues
$job_queue.each do |analyze_job|
  analyze_job.output_dir = output_path
  $common_filters.each do |filter_name, filter|
    analyze_job.add_filter filter
  end
end


#==> Start Analyzing
MAX_INTERVAL.times do |i|
  start_date = DateTime.parse(start_date_str)
  end_date = DateTime.parse(end_date_str)
  cur_date = start_date + i
  if((cur_date - end_date) > 1)
    break
  end
  cur_date_str = cur_date.strftime("%Y%m%d")
  file_path = "#{input_path}/#{cur_date_str}.json"
  if File.exist? file_path
    analyze_json_file(file_path, cur_date)
  end
end


#==> Start Output
$job_queue.each do |analyze_job|
  analyze_job.output_result 
  puts "output_path: #{output_path}"
  analyze_job.before_exit
end
exit
