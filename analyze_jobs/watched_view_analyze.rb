require './analyze_job'
class WatchViewCountAnalyzeJob < AnalyzeJob
  
  def initialize
    @watch_counts = []
    @goal_counts_after_watch = []
    @output_filename = "watch_view_count.output"
    @result = ""
    @visit_count = 0
  end
  # ==> methods derivation Has to implement

  def analyze_session session
    watch_time = 0
    unless isFrontPorch session[0]
      puts session[0]["pageurl"]
      return 
    end
    analyze session do |action|
      pageurl = action["pageurl"]
      #action include watch
      if(pageurl =~ /^http:\/\/www2\.hulu\.jp\/watch\/.*$/ )
        watch_time += 1
        @watch_counts[watch_time] ||= 0
        @watch_counts[watch_time] += 1
      end
      #action include signup_complete
      if(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/signup_complete(\?.*)?$/)
        watch_time.times do |i|
          unless 0 == i
            @goal_counts_after_watch[i] ||= 0
            @goal_counts_after_watch[i] += 1
          end
        end
      end
    end
    @visit_count += 1
  end

  def output_format
    @watch_counts.length.times do |watch_time|
      unless 0 == watch_time 
        @goal_counts_after_watch[watch_time] ||= 0
        @result += "watch at least #{watch_time} video: #{@watch_counts[watch_time]},  and rate is: #{@watch_counts[watch_time] * 100.0 / @visit_count}%   and conversion rate is: #{@goal_counts_after_watch[watch_time] * 100.0 / @watch_counts[watch_time]}%\n"
      end
    end
  end

end

        
