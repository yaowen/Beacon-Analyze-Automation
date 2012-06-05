require 'set'
require 'json'
require 'date'

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

def time_build parts
  line_type = check_type(parts)
  year_idx = 0
  month_idx = 1
  day_idx = 2

  year = parseInt(parts[year_idx])
  month = parseInt(parts[month_idx])
  day = parseInt(parts[day_idx])
    
  timeofday = parts[-2]
  timeofday_parts = timeofday.split(":")
  hour = parseInt(timeofday_parts[0])
  minute = parseInt(timeofday_parts[1])
  second = parseInt(timeofday_parts[2])
  complete_time = Time.new(year,month,day,hour,minute,second, "+00:00")
end


def parse_beacon_file input_path, options = {}
  beacon_file = File.open(input_path, 'r')
  flag = false
  inputLineCount ||= 0
  inputLineLimit = $cmd_params["linelimit"] || -1
  beacon_file.each_line do |line|
    unless flag
      flag = true
      next
    end
    inputLineCount += 1
    if( inputLineCount % 10000 == 0 )
      puts inputLineCount
    end
    if(inputLineLimit != -1 && inputLineCount > inputLineLimit)
      break;
    end
    
    parts = line.split(/\t+/)

    next if parts.length < 10 #error line
    pageurl = parts[5]
    timestamp = time_build parts 
    sid = parts[4]
    cid = parts[3]

    nArray = $sessions[sid]
    if nArray.nil?
      nArray = Array.new
      $sessions[sid] = nArray
    end
    nArray << {:pageurl => pageurl, :visit_time => timestamp}
  end
  beacon_file.close
end

def parse_beacon_files input_dir, options = {}
  traverse_dir(input_dir) do |file|
    if file.to_s =~ /\.tsv$/
      parse_beacon_file(file.to_s)
    end
  end
end


if File.directory? input_path
  parse_beacon_files(input_path)
else
  parse_beacon_file(input_path)
end
    
# ==> Output the final result into indicated file
outputFile = File.open(output_path, 'w')
linecount = 0
$sessions.each do |key, value|
  linecount += 1
  puts linecount if linecount % 10000 == 0
  outputFile.puts value.to_json
end

# ==> Closing all the open files
outputFile.close
