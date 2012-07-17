require 'mongo'

class MongoDBSender
  def initialize
    init_db
  end

  def init_db
    connection = Mongo::Connection.new("10.16.1.35", 27017)
    @db = connection.db("beacon_data")
  end

  def send coll_name, daily_report
    coll = @db.collection(coll_name)
    doc = coll.find_one(
      "timestamp" => daily_report["timestamp"],
      "version" => daily_report["version"]
    )
    if doc.nil?
      insert coll, daily_report
    else
      update coll, doc["_id"], daily_report
    end

  end

  def update coll, id, daily_report
    coll.update({"_id" => id}, {"$set" => daily_report})
  end

  def insert coll, daily_report
    coll.insert(daily_report)
  end

  @@instance = MongoDBSender.new

  def self.instance
    return @@instance
  end

  private_class_method :new
end
