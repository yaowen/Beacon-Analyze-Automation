require 'mysql'

my = Mysql::new("10.20.0.200", "mysqluser", "mojiti", "api_production")
res = my.query("select user_regions.user_id from user_regions inner join users on user_regions.user_id = users.id and region='JP' and is_pending=false and users.joined_at > '2012-07-10 15:00:00' and users.joined_at < '2012-07-16 14:59:59';")

output_file = File.open("register_users.output", "w")
res.each do |row|
  output_file.puts(row[0])
end
