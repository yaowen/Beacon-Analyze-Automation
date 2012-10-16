def front_porch? action
  return false if action["_type"] != "page_load"
  pageurl = action["pageurl"]
  return !(pageurl =~ /^http\:\/\/www2\.hulu\.jp\/(campaign)?(\?.*)?$/).nil? 
end

def conversion? action
  return false if action["_type"] != "page_load"
  pageurl = action["pageurl"]
  return (!(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/((signup_complete)|(thanks))(\?.*)?$/).nil? and (action["userid"] != "0"))
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
    return "origin" if version[0] == "201205153"
    return version[0]
  end
  if pageurl =~ /^http\:\/\/www2\.hulu\.jp\/(\?.*)?$/
    return "origin"
  end
  pageurl = pageurl.split("?")[0]
  pageurl = pageurl.split("/")[-1]
  return pageurl
end

def pretty_session_form session
  result = ""
  result += "#{session[0]["client"]} #{session[0]["sitesessionid"]} #{session[0]["computerguid"]}\t"
  session.each do |action|
    result += "[#{action["visit_time"]}]: #{action["pageurl"]} --> " if action["_type"] == "page_load"
  end
  return result
end
  
def extract_campaign pageurl
  cmp = pageurl.scan(/(&|\?)cmp=(\d+)/)[0]
  unless cmp.nil?
    return cmp[1]
  end
  return "direct"
end
