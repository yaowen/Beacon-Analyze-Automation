def front_porch? action
  return false if action["_type"] != "page_load"
  pageurl = action["pageurl"]
  return !(pageurl =~ /^http\:\/\/www2\.hulu\.jp\/(campaign)?(\?.*)?$/).nil? 
end

def conversion? action
  return false if action["_type"] != "page_load"
  pageurl = action["pageurl"]
  return (!(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/signup_complete(\?.*)?$/).nil? and (action["userid"] != "0"))
end

def signup_start? action
  return false if action["_type"] != "page_load"
  pageurl = action["pageurl"]
  return !(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/(signup|asignup_s1)(\?.*)?$/).nil?
end

def watch_video? action
  return action["_type"] == "play_action"
end

def during? target_time, start_date, end_date 
  return (target_time > start_date and target_time < end_date)
end

def extract_version pageurl
  version = pageurl.scan(/[\?|&]ver=(\d+)/)[0]
  unless version.nil?
    return version[0]
  end
  if pageurl =~ /^http\:\/\/www2\.hulu\.jp\/(\?.*)?$/
    return "origin"
  end
  pageurl = pageurl.split("?")[0]
  pageurl = pageurl.split("/")[-1]
  return pageurl
end
  
def extract_campaign pageurl
  cmp = pageurl.scan(/(&|\?)cmp=(\d+)/)[0]
  unless cmp.nil?
    return cmp[1]
  end
  return "direct"
end
