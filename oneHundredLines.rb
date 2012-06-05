file = File.open("#{ARGV[0]}", 'r')
p file.to_s
outputline = Integer(ARGV[1]) || 100
p outputline
linecount = 0
file.each_line do |line|
    p line
    linecount += 1
    if linecount > 100  
        break
    end
end
