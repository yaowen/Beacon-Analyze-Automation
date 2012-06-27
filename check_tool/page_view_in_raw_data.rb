input = ARGV[0]
file = File.open(input, 'r')
flag = false
landing_page = {}

def extract_version pageurl
  version = pageurl.scan(/\?ver=(\d+)/)[0]
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


file.each_line do |line|
  unless flag
    flag = true
    next
  end
  if line =~ /^2012\t6\t20\t.*http\:\/\/www2\.hulu\.jp\/(\?.*)?\t.*/
    parts = line.split(/\t/)
    version = extract_version(parts[8])
    landing_page[version] ||= 0
    landing_page[version] += 1
  end
end

landing_page.each do |key, value|
  puts "#{key}: #{value}"
end
