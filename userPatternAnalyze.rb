require 'json'

class UserPattern
    attr_accessor :actions, :marks

    def initialize
        @hash_code = 0
        @actions = Array.new
        @filters = Array.new
    end


    def add_action user_action
        @actions << user_action
        @hash_code += user_action.page_url.hash 
        qualified(user_action)
    end

    def << filter
        @filters << filter
        @mark[filter.filter_mark] = false;
    end

    def qualified action
        @filters.each do |filter|
            :marks[filter.filter_mark] = filter.qualified(self, action)
        end
    end

    def get_action index
        @actions[index]
    end

    def size
        @actions.length
    end

    def eql? another
        return false if size != another.size
        size.times do |i|
            return false unless @actions[i].eql? another.get_action(i)
        end
        true
    end

    def hash
        return @hash_code
    end

    def to_s
        content = ""
        @actions.each do |action|
           content += action.to_s 
           content += "\n"
        end
        content
    end
end

class UserPatternAction
    attr_accessor :page_url, :visit_time
    def initialize(page_url, visit_time)
        @page_url = page_url
        @visit_time = visit_time
    end

    def eql? another
        another.page_url == @page_url
    end

    def to_s
        page_url + " " + visit_time
    end
end

class Filter
    attr_accessor: :filter_mark

    def qualified
    end
end

class FilterFPLanding < Filter
    def initialize 
        @filter_mark = :fp_landing
    end

    def qualified user_pattern
        return user_pattern.actions.size == 0 && self.pageurl =~ /^www2.hulu.jp\/(\?.*)?/
    end
end

class FilterViewedPage < Filter

    def intialize filter_mark, page_key_part
        @filter_mark = filter_mark
        @parge_key_part = page_key_part
    end

    def qualified user_pattern, user_action 
        return user_action.page_url =~ /^www2.hulu.jp\/#{page_key_part}.*/
    end
end


pattern_map = Hash.new

lines = IO.readlines("output.txt")
data = lines.first
session_map = JSON.parse(data)
session_map.each do  |sid, user_pattern_actions|
    user_pattern_actions.sort! do |a, b|
        a["visit_time"] <=> b["visit_time"]
    end
    user_pattern = UserPattern.new

    fp_filter = FilterFPLanding.new 
    device_filter = FitlerViewedPage.new :devices, "devices" 
    content_filter = FilterViewedPage.new :content, "content"
    features_filter = FilterViewedPage.new :features, "features"

    user_pattern << fp_filter
    user_pattern << device_filter
    user_pattern << content_filter
    user_pattern << features_filter

    user_pattern_actions.each do |user_pattern_action|
        pageurl = user_pattern_action["pageurl"].split("?")[0]
        upa = UserPatternAction.new(pageurl, user_pattern_action["visit_time"])
        user_pattern.add_action(upa)
    end
    count = 0
    count = pattern_map[user_pattern] if pattern_map.include? user_pattern
    count += 1
    pattern_map[user_pattern] = count
end

sorted_pattern_map = pattern_map.sort do |a, b|
    a[1] <=> b[1]
end

sorted_pattern_map.each do |user_pattern, count|
    puts count.to_s + " ====> "
    puts user_pattern.to_s
end






