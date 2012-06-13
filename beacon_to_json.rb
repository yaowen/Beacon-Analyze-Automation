require 'set'
require 'json'
require 'date'
require './raw_actions/play_action'
require './raw_actions/page_load_action'
require './raw_actions/signup_action'
require './raw_actions/slider_action'

$cmd_params = Hash.new

PLAY_ACTION = "play_action"
PAGE_LOAD_ACTION = "page_load_action"
SIGNUP_ACTION = "signup_action"
SLIDER_ACTION = "slider_action"

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

def parseInt string
    if string =~ /^0\d*$/
        Integer(string[1..-1])
    else
        Integer(string)
    end
end

#since a beacon line may include page_type which may affect other fields postion
def check_type parts
  return parts.length == FIELDS_NUM ? :with_page_type : :without_page_type 
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

def generate_action action_type
  if PLAY_ACTION == action_type
    return PlayAction.new
  elsif PAGE_LOAD_ACTION == action_type
    return PageViewAction.new
  elsif SIGNUP_ACTION == action_type
    return SignUpAction.new
  elsif SLIDER_ACTION == action_type
    return SliderAction.new
  end
  return nil
end

def generate_action_type_with_mark head_line
  puts head_line
  if (head_line =~ /.*signup_action.*/)
    puts "signup_action"
    return SIGNUP_ACTION
  elsif(head_line =~ /.*page_load.*/)
    puts "page_load"
    return PAGE_LOAD_ACTION
  elsif (head_line =~ /.*play_action.*/)
    puts "play_action"
    return PLAY_ACTION
  elsif (head_line =~ /.*slider_action.*/)
    puts "slider_action"
    return SLIDER_ACTION
  end
  return nil
end

def parse_beacon_file input_path, options = {:action_type => "page_load_action"}
  beacon_file = File.open(input_path, 'r')
  flag = false
  inputLineCount ||= 0
  inputLineLimit = $cmd_params["linelimit"] || -1
  action_type = generate_action_type_with_mark(beacon_file.first)
  beacon_file.each_line do |line|
    action = generate_action(action_type);
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
    add_element_to_hash_set $sessions, action.sid, action.to_hash
    add_element_to_hash_set $visitors, action.cid , action.to_hash
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
