require 'set'
# ==> Definition Part
set = Set.new
aFile = File.new("4006.tsv")
bFile = File.new("4003.tsv")
session_count = 0
bset = Set.new
linecount = 0
SESSION_INDEX = 4
CID_INDEX = 3
aggregate_field = CID_INDEX

# ==> Logic Part
aFile.each_line do |line|
    linecount += 1
    puts linecount if linecount % 10000 == 0
    parts = line.split(/\t+/)
    bset.add(parts[4])
    line_type = parts.length > 13 ? :with_pagetype : :without_pagetype 

    pvis = (line_type == :with_pagetype) ? parts[10] : parts[9]
    timestamp = (line_type == :with_pagetype) ? parts[12] : parts[11]
    if line =~ /2012\t5\t19.*http:\/\/www2\.hulu\.jp\/(.*ver=201205153.*)\t.*(0[0-9]|1[0-4]):\d+:\d+.*/ and !set.include?(parts[aggregate_field]) 
    #if line =~ /http:\/\/www2\.hulu\.jp\/campaign(\?.*)?/ and !set.include?(parts[4])
        #puts parts[5] + " " + parts[2] + " " + timestamp
        session_count = session_count + 1  
        set.add(parts[aggregate_field])
    elsif line =~ /2012\t5\t1[6-8].*http:\/\/www2\.hulu\.jp\/(.*201205152.*)\t.*/ and !set.include?(parts[aggregate_field]) 
      #puts parts[5] + " " + parts[2] + " " + timestamp
      session_count = session_count + 1
      set.add(parts[aggregate_field])
    end

    #if line =~ /http:\/\/www2\.hulu\.jp\/(\?.*)?\t/

    #p line

end
p session_count
p set.length
p bset.length

aFile.close

conversion_count = 0;
bFile.each_line do |line|
    parts = line.split("\t")
    if line =~ /\thttps?:\/\/secure\.hulu\.jp\/signup_complete(\?.*)?\t/
       conversion_count = conversion_count + 1 if set.include?(parts[aggregate_field])
       set.delete(parts[aggregate_field]) if set.include?(parts[aggregate_field])
    end
end
bFile.close

p conversion_count
p conversion_count * 1.0/ session_count
p "end"
