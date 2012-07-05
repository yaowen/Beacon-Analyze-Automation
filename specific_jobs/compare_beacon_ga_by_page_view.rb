require 'set'

#==> deal with beacon pageview
beacon_file = File.open('metrics/round_1_page_view_count.output')

beacon_compare_parts = {}
beacon_file.each_line do |line|
  parts = line.split(" ")
  pageurl = parts[1]
  count = parts[2]
  if pageurl.nil?
    puts "line is " + line
    next
  end
  compare_parts = pageurl.split(/\?/)
  compare_parts[1] ||= "$"
  compare_part = compare_parts[1]
  unless beacon_compare_parts.include?(compare_part) 
    beacon_compare_parts[compare_part] = count
  end
end

#==> deal with ga pageview
ga_file = File.open('metrics/ga_round_1_unsample_page_view_count.csv')
ga_compare_parts = {}
ga_file.each_line do |line|
  line = line.gsub("\"", "")
  parts = line.split(",")
  pageurl = parts[0]
  count = parts[1] || 0
  compare_parts = pageurl.split(/\?/)
  compare_parts[1] ||= "$"
  compare_part = compare_parts[1] 
  #puts "fuck: " + compare_part + " " + count.to_s
  
  ga_compare_parts[compare_part] = count
end

puts ga_compare_parts.include? "cmp=399&wapr=4fb451ec"
#puts ga_compare_parts["partner=vc&wapr=4fbba7ec"]


total_diff = 0
total_diff_lines = 0
total_beacon_count = 0
total_ga_count = 0
total_beacon_lines = 0
total_ga_lines = 0

ga_compare_parts.each do |ga_compare_part, count|
  if count =~ /^\d+$/
    total_ga_count += Integer(count)
    total_ga_lines += 1
  end
end

beacon_compare_parts.each do |beacon_compare_part, count|
  if count =~ /^\d+$/
    total_beacon_lines += 1
    total_beacon_count += Integer(count)
  end
  unless ga_compare_parts.include? beacon_compare_part
    #puts beacon_compare_part + " " + count.to_s
    total_diff_lines += 1
    if count =~ /^\d+$/
      total_diff += Integer(count)
    elsif
      puts "error num: #{count}"
    end
  else
    if count =~ /^\d+$/
      diff = Integer(count) - Integer(ga_compare_parts[beacon_compare_part])
      if diff < 0
        puts "#{Integer(count)}  #{Integer(ga_compare_parts[beacon_compare_part])}"
      end
      total_diff += diff
    end
  end

end
puts "final ga lines: #{total_ga_lines}"
puts "final ga count: #{total_ga_count}"
puts "final beacon lines: #{total_beacon_lines}"
puts "final beacon count: #{total_beacon_count}"
puts "final total diff: #{total_diff}"
puts "final total diff lines: #{total_diff_lines}"

