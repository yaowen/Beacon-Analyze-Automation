require 'set'

sids = Set.new

#==> deal with ga pageview
ga_file = File.open("#{ARGV[0]}", 'r')
ga_file.each_line do |line|
  line = line.gsub("\"", "")
  parts = line.split(",")
  sessionid = parts[0]
  #puts "fuck: " + compare_part + " " + count.to_s
  sids.add sessionid
end

tempfile = File.open("metrics/visit_number_ga.output", "w")
sids.each do |sid|
  tempfile.puts(sid)
end


