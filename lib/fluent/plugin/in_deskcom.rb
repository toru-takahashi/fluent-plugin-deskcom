module Fluent
class DeskcomInput < Fluent::Input
  Fluent::Plugin.register_input('deskcom', self)

  # unsupported yet: nest flat
  OUTPUT_FORMAT_TYPE = %w(simple)
  # unsupported yet: brand article reply ~
  INPUT_API_TYPE = %w(cases replies)
  DEFAULT_PER_PAGE = 50

  SORT_DIRECTION_TYPE=%w(asc desc)

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
  config_param :interval,             :integer,:default => 5
  config_param :sort_direction,       :string, :default => 'asc'

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

    if !SORT_DIRECTION_TYPE.include?(@sort_direction)
      raise Fluent::ConfigError, "sort_direction value undefined #{@sort_direction}"
    end

    if !@consumer_key || !@consumer_secret || !@oauth_token || !@oauth_token_secret
      raise Fluent::ConfigError, "missing values in consumer_key or consumer_secret or oauth_token or oauth_token_secret"
    end

    if !@store_file
      $log.warn("stored_time_file path is missing")
    end

    @tick = @interval * 60

    @stored_time = load_store_file
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
    super
    @thread.terminate
    @thread.join
  end

  def run
    while true
      @started_time = Time.now.to_i
      get_stream
      save_store_file unless !@store_file
      sleep @tick
    end
  end

  def get_stream
    page = 1
    loop do
      cases = nil
      begin
        cases = Desk.cases(:since_updated_at => @stored_time, :max_updated_at => @started_time,
                           :page => page, :per_page => @per_page,
                           :sort_field => 'updated_at', :sort_direction => @sort_direction)
      rescue Desk::NotFound => e
        puts "No more records: #{e.message}"
        break
      end

      if @input_api == 'cases' then
        cases.each do |c|
          get_content(c)
        end
        $log.info "Case total entries: #{cases.total_entries} page: #{page}"

      elsif @input_api == 'replies'
        cases.each do |c|
          Desk.case_replies(c.id).each do |r|
            r[:case_id] = c.id
            get_content(r) if c.count > 0
          end
        end
        $log.info "Case total entries with replies: #{cases.total_entries} page: #{page}"
      end

      page = page + 1
      # if getting above 500 pages limit for a search
      #   (http://dev.desk.com/API/cases/#list), reset the reference point and
      #   the page count to 1
      if page >= 500
        if @sort_direction == 'asc'
          # if sorting by ascending 'updated_at', reset the lower filter limit
          #   to focus on the upper part of the records that would reside in the
          #   'pages' past 500
          @stored_time = cases.map(&:updated_at).sort.last
        else
          # if sorting by descending 'updated_at', reset the upper filter limit
          #   to focus on the lower part of the records that would reside in the
          #   'pages' past 500
          @started_time = cases.map(&:updated_at).sort.first
        end
        page = 1
      end
    end
  rescue => e
    $log.error "deskcom run: #{e.message}"
  end

  def get_content(status)
    case @output_format
    when 'simple'
      record = Hash.new
      status.each_pair do |k,v|
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
