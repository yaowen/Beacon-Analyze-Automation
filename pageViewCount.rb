require 'set'
set = Set.new
aFile = File.new("3938.tsv")
session_count = 0
bset = Set.new
pv_count = Array.new
(0..7).each do |i|
    pv_count[i] = 0
end
pv_total = 0
linecount = 0
aFile.each_line do |line|
    linecount += 1
    puts linecount if linecount % 10000 == 0
    parts = line.split(/\t+/)
    bset.add(parts[4])
    if line =~ /http:\/\/www2\.hulu\.jp\/(\?.*)?\t/ and !set.include?(parts[4])
    #if line =~ /http:\/\/www2\.hulu\.jp\/campaign(\?.*)?/ and !set.include?(parts[4])
       # p parts[5]
        session_count = session_count + 1  
        set.add(parts[4])
    end

    #if line =~ /http:\/\/www2\.hulu\.jp\/(\?.*)?\t/
    if line =~ /http:\/\/www2\.hulu\.jp\/\t/
        pv_total += 1
    end

    #p line

    (0..7).each do |i|
        #if line =~ /2012\t5\t#{i}.*http:\/\/www2\.hulu\.jp\/(\?.*)?\t.*(1[5-9]|2[0-3]):\d+:\d+.*/
        if line =~ /2012\t5\t#{i}.*http:\/\/www2\.hulu\.jp\/\t.*(1[5-9]|2[0-3]):\d+:\d+.*/
            #puts line
            pv_count[i] += 1
        #elsif line =~ /2012\t5\t#{i+1}.*http:\/\/www2\.hulu\.jp\/(\?.*)?\t.*(0[0-9]|1[0-4]):\d+:\d+.*/
        elsif line =~ /2012\t5\t#{i+1}.*http:\/\/www2\.hulu\.jp\/\t.*(0[0-9]|1[0-4]):\d+:\d+.*/
            #puts line
            pv_count[i] += 1
        end
    end
end
p "total page view for front_porch will be " + pv_total.to_s
(0..7).each do |i|
    p "page view for front_porch on 5/#{i} is " + pv_count[i].to_s
end
p session_count
p set.length
p bset.length

aFile.close

aFile = File.new("3939.tsv")
conversion_count = 0;
aFile.each_line do |line|
    parts = line.split("\t")
    if line =~ /signup_complete/ 

       conversion_count = conversion_count + 1 if set.include?(parts[4])
        set.delete(parts[4]) if set.include?(parts[4])
    end
end

p conversion_count
p conversion_count * 1.0/ session_count

