require 'set'
file_name_a = ARGV[0]
file_name_b = ARGV[1]

file_a = File.open(file_name_a, 'r')
file_b = File.open(file_name_b, 'r')

set_a = Set.new
set_b = Set.new
#assume two files each line a number or something
file_a.each_line do |line|
  set_a.add line
end

file_inter = File.open("intersec.output", "w")
file_outer = File.open("outersec.output", "w")

file_b.each_line do |line|
  set_b.add line
  if set_a.include? line
    file_inter.puts(line)
  else
    file_outer.puts(line)
  end
end


file_a.close
file_b.close
file_inter.close
file_outer.close
