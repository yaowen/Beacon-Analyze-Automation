require './job_config'
require 'json'

$cmd_params = Hash.new

# ==> Analyze Command Parameter
ARGV.each do |command_param|
  key, value = command_param.split("=")
  $cmd_params[key] = value
end

def validate_param key
  puts $cmd_params
  while $cmd_params[key].nil?
    puts "Missing #{key}, Please enter: "
    value = gets
    unless value.nil? || value == '\n'
      $cmd_params[key] = value.split(/\n/)[0]
      break
    end
  end
end

validate_param "input"
validate_param "output"

$input_path = $cmd_params["input"]
$output_path = $cmd_params["output"]

$writed_files = {}

def write_to_temp_file action
  date_str = action.date_str
  writing_file = nil
  if $writed_files.include? date_str
    writing_file = $writed_files[date_str]
  else
    writing_file = File.open("#{$output_path}/#{date_str}.temp_json", 'w')
    $writed_files[date_str] = writing_file
  end
  writing_file.puts action.to_hash.to_json
end

def traverse_dir(file_path)
  if File.directory? file_path
    Dir.foreach(file_path) do |file|
      if file != "." and file != ".."
        traverse_dir(file_path + "/" + file) do |x|
          yield x
        end
      end
    end
  else
    yield file_path
  end
end

def add_element_to_hash_set container, key, element
  if key.nil? or "" == key
    return
  end
  nArray = container[key]
  if nArray.nil?
    nArray = Array.new
    container[key] = nArray
  end
  nArray << element;
end

def extract_action_type_with_mark head_line
  parts = head_line.split(/\t/)
  return parts[-2]
end


def divide_beacon_file input_path
  job_config = JobConfig.new
  job_config.load('./job.yml')
  beacon_file = File.open(input_path, 'r')
  flag = false
  inputLineCount ||= 0
  inputLineLimit = $cmd_params["linelimit"] || -1
  action_type = extract_action_type_with_mark(beacon_file.first)
  beacon_file.each_line do |line|
    action = job_config.create_action(action_type);
    unless flag 
      flag = true
      next
    end
    inputLineCount += 1
    if( inputLineCount % 1000 == 0 )
      print (inputLineCount.to_s + "\r")
    end
    action.parse_beacon_line(line)
    write_to_temp_file(action)
  end
  puts
  beacon_file.close
end

# ==> Output the final result into indicated file

def output_to_json container, filename
  puts "output_to_file #{filename}"
  outputFile = File.open(filename, 'w')
  linecount = 0
  container.each do |key, value|
    linecount += 1
    print(linecount.to_s + "\r") if linecount % 1000 == 0
    sorted_value = value.sort do |a, b|
      a["visit_time"] <=> b["visit_time"]
    end
    outputFile.puts sorted_value.to_json
  end
  outputFile.close
end

def divide_beacon_files input_path
  traverse_dir(input_path) do |file|
    if file.to_s =~ /\.tsv$/
      puts "dividing file #{file.to_s}"
      divide_beacon_file(file.to_s)
    end
  end
end

def aggregate_json_file input_path
  job_config = JobConfig.new
  job_config.load('./job.yml')
  json_mid_file = File.open(input_path, 'r')
  inputLineCount ||= 0
  sessions = {}
  visitors = {}
  inputLineLimit = $cmd_params["linelimit"] || -1
  json_mid_file.each_line do |line|
    inputLineCount += 1
    if( inputLineCount % 1000 == 0 )
      print (inputLineCount.to_s + "\r")
    end
    user_action = JSON.parse(line)
    add_element_to_hash_set sessions, user_action["sitesessionid"], user_action
    add_element_to_hash_set visitors, user_action["computerguid"], user_action
  end
  puts
  output_path_dir = input_path.split("/")[0..-2].join("/")
  output_file_name = input_path.split("/")[-1].gsub("temp_json", "json")
  puts "output_path_dir:#{output_path_dir}"
  output_to_json(sessions, output_path_dir + "/session/" + output_file_name)
  output_to_json(visitors, output_path_dir + "/visitors/" + output_file_name)
  json_mid_file.close
end

def aggregate_json_files input_path
  traverse_dir(input_path) do |file|
    if file.to_s =~ /\.temp_json$/
      puts "aggregate file #{file.to_s}"
      aggregate_json_file(file.to_s)
    end
  end
end


if File.directory? $input_path
  divide_beacon_files $input_path
else
  divide_beacon_file $input_path
end

$writed_files.each do |key, file|
  file.close
end

aggregate_json_files $output_path
system("rm #{$output_path}/*.temp_json")


