def front_porch? action
  return false if action["_type"] != "PageViewAction"
  pageurl = action["pageurl"]
  return !(pageurl =~ /^http\:\/\/www2\.hulu\.jp\/(\?.*)?$/).nil? 
end

def conversion? action
  return false if action["_type"] != "PageViewAction"
  pageurl = action["pageurl"]
  return !(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/signup_complete(\?.*)?$/).nil?
end

def signup_start? action
  return false if action["_type"] != "PageViewAction"
  pageurl = action["pageurl"]
  return !(pageurl =~ /^https?:\/\/secure\.hulu\.jp\/(signup|asignup_s1)(\?.*)?$/).nil?
end

def watch_video? action
  return action["_type"] == "PlayAction"
end
  
