require 'date'
require './raw_action'

class PlayAction < RawAction
  attr_reader :sid, :cid
  def initialize
  end

  def parse_beacon_line line
    parts = line.split(/\t/)
    @timestamp = time_build parts
    @cid = parts[3]
    @sid = parts[4]
    @content_id = parts[5]
    @package_id = parts[6]
    @client = parts[-5]
    @os = parts[-4]
  end

  def to_hash
    v_hash = super
    v_hash = v_hash.merge({:content_id => @content_id, :package_id => @package_id, :visit_time => @timestamp, :client => @client, :os => @os})
    return v_hash
  end
end
