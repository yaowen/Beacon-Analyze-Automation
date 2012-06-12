require 'json'
require './analyze_utils'
require './analyze_jobs/goal_numbers_count'
require './analyze_jobs/page_view_count'
require './analyze_jobs/visit_number_count'
require './analyze_jobs/watched_view_analyze'
require './analyze_jobs/os_analyze'
require './analyze_jobs/video_watch_analyze'
require './analyze_jobs/signup_funnel_analyze'

input_path = ARGV[0] || "input.json"
output_dir_path = ARGV[1] || "default.output"

#==> reading from specific files
lines = IO.readlines(input_path)

#==> analyze job list
job_queue = [
  #TestAnalyzeJob.new
  #GoalNumberCountAnalyzeJob.new,
  #WatchViewCountAnalyzeJob.new,
  #VisitNumberCountAnalyzeJob.new,
  #PageViewCountAnalyzeJob.new,
  #OSAnalyzeJob.new,
  VideoWatchAnalyzeJob.new,
  SignupFunnelAnalyzeJob.new
]

lines.each do |line|
  user_pattern_actions = JSON.parse(line)
  #analyze jobs
  job_queue.each do |analyze_job|
    analyze_job.analyze_session user_pattern_actions
  end
end

job_queue.each do |analyze_job|
  analyze_job.output_result output_dir_path
end
exit
