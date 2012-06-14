require 'date'
require './raw_action'

class SliderAction < RawAction
  attr_reader :sid, :cid
  def initialize
  end

  def parse_beacon_line line
    parts = line.split(/\t/)
    @timestamp = time_build parts
    @cid = parts[3]
    @sid = parts[4]
    @pageurl = parts[5]
    @contentid = parts[6]
    @client = parts[-5]
    @os = parts[-4]
  end

  def to_hash
    v_hash = super
    v_hash = v_hash.merge({:contentid => @contentid, :pageurl => @pageurl, :visit_time => @timestamp, :client => @client, :os => @os})
    return v_hash
  end
end