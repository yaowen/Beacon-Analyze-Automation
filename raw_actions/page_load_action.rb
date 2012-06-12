require "./raw_action.rb"
class PageViewAction < RawAction
  attr_reader :sid, :cid
  def initialize
    @timestamp = DateTime.new
    @sid = ""
    @cid = ""
    @pageurl = ""
    @client = ""
    @os = ""
  end

  def parse_beacon_line line 
    parts = line.split(/\t/)
    @timestamp = time_build parts 
    @cid = parts[3]
    @sid = parts[4]
    @pageurl = parts[5]
    @client = parts[6]
    @os = parts[7]
  end

  def to_hash
    v_hash = super
    v_hash = v_hash.merge({:pageurl => @pageurl, :visit_time => @timestamp, :client => @client, :os =>@os})
    return v_hash
  end
end
