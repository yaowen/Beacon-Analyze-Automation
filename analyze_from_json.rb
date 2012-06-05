require './analyze_job'
require 'json'
require './goal_numbers_count'

#==> reading from specific files
lines = IO.readlines("20120531.json")

#==> analyze job list
job_queue = [
  #TestAnalyzeJob.new
  GoalNumberCountAnalyzeJob.new
]

lines.each do |line|
  user_pattern_actions = JSON.parse(line)
  #analyze jobs
  job_queue.each do |analyze_job|
    analyze_job.analyze_session user_pattern_actions
  end
end

job_queue.each do |analyze_job|
  analyze_job.output_result
end
exit
