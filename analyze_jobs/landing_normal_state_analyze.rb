require './analyze_job'

class LandingNormalState
  class StateContext
    LANDING = StateLanding.new(self)
    SIGNUP_START = StateStartup.new(self)
    NOT_SURE = StateNotSure.new(self)
    SIGNUP_COMPLETE = StateSignupComplete.new(self)
    WATCH_VIDEO = StateWatchVideo.new(self)

    def initialize
      @state = nil 
      @state_list = []
      @hash_code = 0
    end

    def set_state n_state
      @state = n_state
      @state_list.add(@state)
      @hash_code = @hash_code * 4 + @state.hash
    end

    def next action
      if state.nil?
        if front_porch? action
          set_state(LANDING)
          return true
        end
        return false
      end
      if front_porch? action
        landing
      elsif signup_start? action
        signup_start
      elsif signup_complete? action
        signup_complete
      elsif watch_video? action
        watch_video
      else
        not_sure
      end
      return true
    end

    def landing
      state.land_page
    end

    def signup_start
      state.signup_start
    end

    def signup_complete
      state.signup_complete
    end

    def watch_video
      state.watch_video
    end

    def not_sure
      state.not_sure
    end

    def states idx
      return @state_list[idx]
    end

    def hash
      return hash_code
    end

    def eql? another
      return false if size != another.size
      size.times do |i|
        return false unless @state_list[i].eql? another.states(i) 
      end
      return true
    end

  end

  class StateLanding
    def initialize context
      @context = context
    end

    def landing_page
    end
    
    def not_sure 
      @context.set_state(StateContext::NOT_SURE)
    end

    def signup_start
      @context.set_state(StateContext::SIGNUP_START)
    end

    def signup_complete
      @context.set_state(StateContext::SIGNUP_COMPLETE)
    end

    def watch_video
      @context.set_state(StateContext::WATCH_VIDEO)
    end

    def hash
      return 0
    end
  end

  class StateSignupStart
    def initialize context
      @context = context
    end

    def landing_page
      @context.set_state(StateContext::NOT_SURE)
    end
    
    def not_sure 
      @context.set_state(StateContext::NOT_SURE)
    end

    def signup_start
    end

    def signup_complete
      @context.set_state(StateContext::SIGNUP_COMPLETE)
    end

    def watch_video
      @context.set_state(StateContext::WATCH_VIDEO)
    end

    def hash
      return 1
    end
  end

  class StateSignupNotSure
    def initialize context
      @context = context
    end

    def landing_page
    end
    
    def not_sure 
    end

    def signup_start
      @context.set_state(StateContext::SIGNUP_START)
    end

    def signup_complete
      @context.set_state(StateContext::SIGNUP_COMPLETE)
    end

    def watch_video
      @context.set_state(StateContext::WATCH_VIDEO)
    end
    
    def hash
      return 2
    end
  end

  class StateSignupComplete
    def initialize context
      @context = context
    end

    def landing_page
      @context.set_state(StateContext::NOT_SURE)
    end
    
    def not_sure 
      @context.set_state(StateContext::NOT_SURE)
    end

    def signup_start
      @context.set_state(StateContext::SIGNUP_START)
    end

    def signup_complete
    end

    def watch_video
      @context.set_state(StateContext::WATCH_VIDEO)
    end

    def hash
      return 3
    end
  end

  class StateWatchVideo
    def initialize context
      @context = context
    end

    def landing_page
      @context.set_state(StateContext::NOT_SURE)
    end
    
    def not_sure 
      @context.set_state(StateContext::NOT_SURE)
    end

    def signup_start
      @context.set_state(StateContext::SIGNUP_START)
    end

    def signup_complete
      @context.set_state(StateContext::SIGNUP_COMPLETE)
    end

    def watch_video
    end

    def hash
      return 4
    end
  end
end

class LandingNormalStateAnalyzeJob

end
    
