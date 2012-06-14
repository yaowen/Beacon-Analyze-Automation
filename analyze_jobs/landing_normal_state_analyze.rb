require './analyze_job'

class LandingNormalState

  class State
    def eql? another
      return hash == another.hash
    end
  end

  class StateLanding < State
    def initialize context
      @context = context
    end

    def landing_page
    end
    
    def not_sure 
      @context.set_state(@context.state_not_sure)
    end

    def signup_start
      @context.set_state(@context.state_signup_start)
    end

    def signup_complete
      @context.set_state(@context.state_signup_complete)
    end

    def watch_video
      @context.set_state(@context.state_watch_video)
    end

    def hash
      return 0
    end

    def to_s
      "landing"
    end

  end

  class StateSignupStart < State
    def initialize context
      @context = context
    end

    def landing_page
      @context.set_state(@context.state_not_sure)
    end
    
    def not_sure 
      @context.set_state(@context.state_not_sure)
    end

    def signup_start
    end

    def signup_complete
      @context.set_state(@context.state_signup_complete)
    end

    def watch_video
      @context.set_state(@context.state_watch_video)
    end

    def hash
      return 1
    end

    def to_s
      "signup_start"
    end

  end

  class StateNotSure < State
    def initialize context
      @context = context
    end

    def landing_page
    end
    
    def not_sure 
    end

    def signup_start
      @context.set_state(@context.state_signup_start)
    end

    def signup_complete
      @context.set_state(@context.state_signup_complete)
    end

    def watch_video
      @context.set_state(@context.state_watch_video)
    end
    
    def hash
      return 2
    end

    def to_s
      "wants know more"
    end
  end

  class StateSignupComplete < State
    
    def initialize context
      @context = context
    end

    def landing_page
      @context.set_state(@context.state_not_sure)
    end
    
    def not_sure 
      @context.set_state(@context.state_not_sure)
    end

    def signup_start
      @context.set_state(@context.state_signup_start)
    end

    def signup_complete
    end

    def watch_video
      @context.set_state(@context.state_watch_video)
    end

    def hash
      return 3
    end

    def to_s
      "signup complete"
    end
  end

  class StateWatchVideo < State
    def initialize context
      @context = context
    end

    def landing_page
      @context.set_state(@context.state_not_sure)
    end
    
    def not_sure 
      @context.set_state(@context.state_not_sure)
    end

    def signup_start
      @context.set_state(@context.state_signup_start)
    end

    def signup_complete
      @context.set_state(@context.state_signup_complete)
    end

    def watch_video
    end

    def hash
      return 4
    end

    def to_s
      "watch video"
    end
  end
  
  class StateContext
    attr_reader :state_landing, :state_signup_start, :state_not_sure, :state_signup_complete, :state_watch_video

    def initialize
      @state_landing = StateLanding.new(self)
      @state_signup_start = StateSignupStart.new(self)
      @state_not_sure = StateNotSure.new(self)
      @state_signup_complete = StateSignupComplete.new(self)
      @state_watch_video = StateWatchVideo.new(self)

      @state = nil 
      @state_list = []
      @hash_code = 0

      #==> marks
      @mark_conversion = false
    end

    def update_marks n_state
      puts "hash: #{n_state.hash}"
      if n_state.eql? @state_signup_complete
        @mark_conversion = true
      end
    end

    def pattern_conversion?
      return @mark_conversion
    end

    def set_state n_state
      @state = n_state
      @state_list << @state
      @hash_code = @hash_code * 4 + @state.hash
      update_marks n_state
    end

    def next action
      if @state.nil?
        if front_porch? action
          set_state(@state_landing)
          return true
        end
        return false
      end
      if front_porch? action
        landing
      elsif signup_start? action
        signup_start
      elsif conversion? action
        signup_complete
      elsif watch_video? action
        watch_video
      else
        not_sure
      end
      return true
    end

    def landing
      @state.landing_page
    end

    def signup_start
      @state.signup_start
    end

    def signup_complete
      @state.signup_complete
    end

    def watch_video
      @state.watch_video
    end

    def not_sure
      @state.not_sure
    end

    def states idx
      return @state_list[idx]
    end

    def hash
      return @hash_code
    end

    def eql? another
      return false if size != another.size
      size.times do |i|
        return false unless @state_list[i].eql? another.states(i) 
      end
      return true
    end

    def size
      return @state_list.length
    end

    def to_s
      content = ""
      flag = true

      if @state_list.length == 0
        return "not landing pattern"
      end

      @state_list.each do |state|
        if flag
          content += "#{state}"
          flag = false
          next
        end
        content += "->#{state}"
      end
      return content
    end

  end
end

class LandingNormalStateAnalyzeJob < AnalyzeJob
  
  def initialize
    @pattern_count = Hash.new 
    @pattern_conversion_count = Hash.new
    @output_filename = "landing_normal_state"
    @result = ""
  end

  # ==> methods derivation Has to implement
  def analyze_session session
    pattern = LandingNormalState::StateContext.new
    analyze session do |action|
      pattern.next(action)
    end
    @pattern_count[pattern] ||= 0
    @pattern_count[pattern] += 1

    @pattern_conversion_count[pattern] ||= 0
    if pattern.pattern_conversion?
      @pattern_conversion_count[pattern] += 1
    end
  end

  def output_format
    sort_patterns = @pattern_count.sort do |a,b|
      a[1] <=> b[1]
    end
    sort_patterns.each do |pattern, count|
      conversion = @pattern_conversion_count[pattern]
      @result += "#{pattern.to_s} in #{count} sessions, and conversions #{conversion}\n, rate is #{conversion * 100.0 / count}%"
    end
  end

end
    
      
