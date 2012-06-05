require 'json'
require 'set'
require 'date'

second_page_visit = Hash.new

session_map = Hash.new
count = 0
bounce_count = 0
landing_count = 0
second_count = 0
pv_count = 0
page_view_count_after_landing = 0

start_time = DateTime.parse("2012-05-23 00:00:00 Tokyo")
end_time = DateTime.parse("2012-05-24 00:00:00 Tokyo")

url_types = Hash.new
pv_url_types = Hash.new

#prepare data
1.times do |i|
  lines = IO.readlines("2012052#{i+3}_0525.json")
  lines.each do |line|
    user_pattern_actions = JSON.parse(line)
    count += 1
    if( count % 10000 == 0)
      puts count
    end
    action_count = 0
    isLanding = false
   
    
    user_pattern_actions.each do |user_pattern_action|
      action_count += 1

      pageurl = user_pattern_action["pageurl"]#.split("?")[0]
      visit_time = DateTime.parse(user_pattern_action["visit_time"])

      if visit_time < end_time and visit_time > start_time
        pv_count += 1
        pv_url_types[pageurl] ||= 0
        pv_url_types[pageurl] += 1
      end

      if 1 == action_count and pageurl =~ /^http:\/\/www2.hulu.jp\/(\?ver=201205224)$/ 
        if visit_time < end_time and visit_time > start_time
          
          url_types[pageurl] ||= 0
          url_types[pageurl] += 1

          landing_count += 1
          isLanding = true
          puts pageurl
          if user_pattern_actions.length == 1
            #puts user_pattern_actions.to_s
            bounce_count += 1
          end
        end
      end

      page_view_count_after_landing += 1 if isLanding
      
      if isLanding and 2 == action_count
        second_page_visit[pageurl] ||= 0
        second_page_visit[pageurl] += 1
      end
    end
  end
end

puts "count: #{count}"
puts "total_pv_count: #{pv_count}"
puts "url_types: #{url_types.length}"
puts "bounce_count: #{bounce_count}"
puts "landing_count: #{landing_count}"
puts "page_view_after_landing: #{page_view_count_after_landing}"
puts "pages/visits: #{page_view_count_after_landing * 1.0 / landing_count}"
puts "rate: #{bounce_count * 1.0 / landing_count}"


sorted_map = second_page_visit.sort do |a, b|
  b[1] <=> a[1]
end

sorted_map2 = url_types.sort do |a, b|
  b[1] <=> a[1]
end

sorted_map3 = pv_url_types.sort do |a, b|
  b[1] <=> a[1]
end

linecount = 0

puts "=========second page url distribution====="
sorted_map.each do |key, value|
  linecount += 1
  if(linecount > 10)
    break
  end
  puts "#{key} ==> #{value}   rate: #{value * 100.0 / landing_count}%"
end

linecount = 0
puts "==========landing url distribution ======"
sorted_map2.each do |key, value|
  linecount += 1
  if(linecount > 10)
    break
  end
  puts "#{key} ==> #{value}"
end

linecount = 0
puts "==========pv url distribution ============"
sorted_map3.each do |key, value|
  linecount += 1
  if(linecount > 10)
    break
  end
  puts "#{key} ==> #{value}"
end
exit

