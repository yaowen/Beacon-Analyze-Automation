EXPIRE_TIME = 1000
DURATION = 60

def when_file_exist file_path  
  EXPIRE_TIME.times do |i|
    puts "#{i} times check the file #{file_path} existence"
    if check_file_exist file_path
      yield
      break
    end
    sleep(DURATION)
  end
end

def check_file_exist file_path
  File.exist? file_path
end




