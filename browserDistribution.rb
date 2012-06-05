aFile = File.new("3989.tsv")
browser = Hash.new
linecount = 0
aFile.each_line do |line|
    linecount += 1
    if(linecount % 10000 == 0)
        puts linecount.to_s
    end

    parts = line.split(/\t+/)
    if(parts[0] == "year" || parts.length <= 11)
        next
    end
    line_type = parts.length > 13 ? :with_pagetype : :without_pagetype
    browser_type = (line_type == :with_pagetype) ? parts[7] : parts[6] 
    (0..7).each do |i|
        if (line =~ /2012\t5\t#{i}.*http:\/\/www2\.hulu\.jp\/(\?.*)?\t.*(1[5-9]|2[0-3]):\d+:\d+.*/ || line =~ /2012\t5\t#{i+1}.*http:\/\/www2\.hulu\.jp\/(\?.*)?\t.*(0[0-9]|1[0-4]):\d+:\d+.*/ )
            browser[i.to_s + "_" + browser_type] ||= 0
            browser[i.to_s + "_" + browser_type] += 1
            break
        end
    end
end

browser = browser.sort

browser.each do |line|
    puts line[0].to_s + " => " + line[1].to_s
end




