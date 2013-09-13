require 'yaml'
require './post_beacon_mission'
require './raw_action'

class JobConfig

  def initialize
    @job_types = {}
    @job_profiles = []
    @common_params = []
  end

  def load job_yml
    File.open(job_yml) do |yf|
      job_config = YAML.load(yf)
      @job_profiles = job_config["jobs"]
      @common_params = job_config["common_params"]
      job_config["job_types"].each do |job_type|
        type_name = job_type["type_name"]
        @job_types[type_name] = job_type
      end
    end
  end

  def generate_fields job_type
    #common fields
    common_param_str = ""
    @common_params.each do |common_param|
      common_param_str += "#{common_param} "
    end
    additional_param_str = ""
    job_type["additional_fields"].each do |additional_field|
      additional_param_str += "#{additional_field} "
    end
    return "time #{common_param_str} #{additional_param_str} #{job_type["type_name"]}"
  end

  def generate_jobs start_date, end_date
    jobids = []
    @job_profiles.each do |job_profile|
      job_type = @job_types[job_profile["job_type"]]
      jobids << post_beacon_data(
        :page_regex => job_profile["page_regex"],
        :job_title => job_profile["job_title"],
        :start_date => start_date,
        :end_date => end_date,
        :input_file_types => job_profile["input_file_types"],
        :additional_fields => generate_fields(job_type),
        :region => ($region == "jp" ? "2" : "1")
      )
    end
    return jobids
  end

  def create_action job_type_name
    action  = RawAction.new
    job_type = @job_types[job_type_name]
    action.load(@common_params + job_type["additional_fields"], job_type_name)
    return action
  end
end


