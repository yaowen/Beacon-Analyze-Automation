require 'set'
require 'json'
require 'date'
require './job_config'

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

# ==> Constants
FIELDS_NUM = 13

# ==> Global Variables
$sessions = Hash.new    #normally use session to aggregate all the track record
$visitors = Hash.new

# ==> File Settings
input_path = $cmd_params["input"] 
output_path = $cmd_params["output"]

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


#since a beacon line may include page_type which may affect other fields postion

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

def parse_beacon_file input_path, options = {:action_type => "page_load_action"}
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
    if(inputLineLimit != -1 && inputLineCount > inputLineLimit)
      break;
    end
    action.parse_beacon_line(line)
    add_element_to_hash_set $sessions, action["sitesessionid"], action.to_hash
    add_element_to_hash_set $visitors, action["computerguid"], action.to_hash
  end
  puts
  beacon_file.close
end

def parse_beacon_files input_dir, options = {}
  traverse_dir(input_dir) do |file|
    if file.to_s =~ /\.tsv$/
      puts "parsing file #{file.to_s}"
      parse_beacon_file(file.to_s)
    end
  end
end

# ==> Parse beacon files into action lists which group on sessionid
# and computerguid, and order by timestamp
if File.directory? input_path
  parse_beacon_files(input_path)
else
  parse_beacon_file(input_path)
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
      a[:visit_time] <=> b[:visit_time]
    end
    outputFile.puts sorted_value.to_json
  end
  outputFile.close
end

output_to_json($sessions, output_path + "_session")
output_to_json($visitors, output_path + "_visitors")
