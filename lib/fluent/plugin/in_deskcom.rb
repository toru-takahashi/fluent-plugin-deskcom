module Fluent
class DeskcomInput < Fluent::Input
  Fluent::Plugin.register_input('deskcom', self)

  # un-support yet: nest flat
  OUTPUT_FORMAT_TYPE = %w(simple)
  # un-support yet: brand article reply ~
  INPUT_API_TYPE = %w(cases replies)
  DEFAULT_PER_PAGE = 50

  config_param :subdomain,            :string, :default => nil
  config_param :consumer_key,         :string, :default => nil
  config_param :consumer_secret,      :string, :default => nil
  config_param :oauth_token,          :string, :default => nil
  config_param :oauth_token_secret,   :string, :default => nil
  config_param :store_file,           :string, :default => nil
  config_param :output_format,        :string, :default => 'simple'
  config_param :input_api,            :string, :default => 'cases'
  config_param :tag,                  :string, :default => nil
  config_param :time_column,          :string, :default => nil

  def initialize
    super
    require 'desk'
    require 'yaml'
    require 'pathname'
  end


  def configure(conf)
    super
    if !OUTPUT_FORMAT_TYPE.include?(@output_format)
      raise Fluent::ConfigError, "output_format value undefined #{@output_format}"
    end

    if !INPUT_API_TYPE.include?(@input_api)
      raise Fluent::ConfigError, "input_api value undefined #{@input_api}"
    end

    if !@consumer_key || !@consumer_secret || !@oauth_token || !@oauth_token_secret
      raise Fluent::ConfigError, "missing values in consumer_key or consumer_secret or oauth_token or oauth_token_secret"
    end

    if !@store_file
      $log.warn("stored_time_file path is missing")
    end


    @stored_time = load_store_file
    @started_time = Time.now.to_i
    @per_page = DEFAULT_PER_PAGE

    Desk.configure do |config|
      config.subdomain          = @subdomain
      config.consumer_key       = @consumer_key
      config.consumer_secret    = @consumer_secret
      config.oauth_token        = @oauth_token
      config.oauth_token_secret = @oauth_token_secret
    end
  end

  def start
    super
    @thread = Thread.new(&method(:run))
  end

  def shutdown
    @thread.kill
  end

  def run
    page = 1
    if @input_api == 'cases' then
      begin
        cases = Desk.cases(:since_updated_at => @stored_time, :page => page, :per_page => @per_page)
        # Sleep for rate limit
        # ToDo: Check body "Too Many Requests" and Sleep
        sleep(1)

        cases.each do |c|
          get_content(c)
        end

        page = page + 1
      end while cases.total_entries > (@per_page*page)
    elsif @input_api == 'replies'
      begin
        cases = Desk.cases(:since_updated_at => @stored_time, :page => page, :per_page => @per_page)        
        # Sleep for rate limit
        # ToDo: Check body "Too Many Requests" and Sleep
        sleep(1)

        cases.each do |c|
          Desk.case_replies(c.id).each do |r|
            # Sleep for rate limit
            # ToDo: Check body "Too Many Requests" and Sleep
            sleep(1)
            
            r[:case_id] = c.id
            get_content(r) if c.count > 0
          end
        end
        page = page + 1
      end while cases.total_entries > (@per_page*page)
    end
    save_store_file unless !@store_file
  rescue => e
    $log.error "deskcom run: #{e.message}"
  end

  def get_content(status)
    case @output_format
    when 'simple'
      record = Hash.new
      status.each_pair do |k,v|
        # @stored_time <= store data's updated time < @started_time
        if (k == 'updated_at') then
          at_time = Time.parse(v).to_i
          if (at_time >= @started_time) || (at_time < @stored_time) then
            next
          end
        end

        if (!@time_column.nil? && k == "#{@time_column}") then
          @time_value = Time.parse(v).to_i rescue nil
        end

        if (k == '_links') then
          next
        end

        if v.kind_of? Hashie::Deash then
          record.store(k, v.to_json)
        else
          record.store(k, v)
        end
      end
    end

    if !@time_value.nil? then
      Engine.emit(@tag, @time_value, record)
    else
      Engine.emit(@tag, @started_time,  record)
    end
  rescue => e
    $log.error "deskcom get_content: #{e.message}"
  end

  # => int
  def load_store_file
    begin
      f = Pathname.new(@store_file)
      stored_time = 0
      f.open('r') do |f|
        stored = YAML.load_file(f)
        stored_time = stored[:time].to_i
      end
      $log.info "deskcom: Load #{@store_file}: #{@stored_time}"
    rescue => e
      $log.warn "deskcom: Can't load store_file #{e.message}"
      return 0
    end
    return stored_time
  end

  def save_store_file
    begin
      f = Pathname.new(@store_file)
      f.open('w') do |f|
        data = {:time => @started_time}
        YAML.dump(data, f)
      end
      $log.info "deskcom: Save started_time: #{@started_time} to #{@store_file}"
    rescue => e
      $log.warn "deskcom: Can't save store_file #{e.message}"
    end
  end

end
end
