class Injest::Middleware
  HEADERS_BLACKLIST = %w[HTTP_COOKIE].freeze

  attr_reader :configuration
  attr_reader :request_type, :env, :consumer, :subject

  def initialize(app, processor: nil)
    @app = app
    init_configuration

    @processor = processor

    @consumer = nil
    @subject = nil
  end

  def call(env)
    dup._call(env)
  end

  def _call(env)
    @env = env
    set_request_type
    return @app.call(env) unless trackable?

    @request_started_on = Time.now
    @status, @headers, @response = @app.call(env)
    @request_ended_on = Time.now

    set_subject
    set_consumer

    data = build_data
    data = @processor.call(env, data) unless @processor.nil?

    append(data)

    [@status, @headers, @response]
  end

  def init_configuration
    @configuration = Injest::Configuration.instance
  end

  private

  def append(data)
    Injest::Writer.instance.append(data)
  end

  def build_data
    {
      request_id: env["action_dispatch.request_id"],
      time: @request_started_on.to_i,
      human_time: @request_started_on,
      type: request_type,
      request: build_request,
      response: {
        status: @status,
        body: response_body(@response),
        headers: @headers
      },
      delta: @request_ended_on - @request_started_on,
      log_type: 'audit'
    }
  end

  def build_request
    {
      method: env['REQUEST_METHOD'],
      server_name: env['SERVER_NAME'],
      port: env['SERVER_PORT'],
      query_string: env['QUERY_STRING'],
      path: env['PATH_INFO'],
      scheme: env["rack.url_scheme"],
      remote_addr: env['REMOTE_ADDR'],
      remote_ip: env['action_dispatch.remote_ip'].to_s,
      formats: (env["action_dispatch.request.formats"] || []).map(&:to_s),
      headers: get_request_headers,
      subject: subject,
      context: get_context(env['action_dispatch.request.parameters'], env["action_dispatch.request.request_parameters"]),
      auth_scheme: env["rack.session"].fetch('auth_scheme', [])
    }
  end

  def get_context(data, params)
    data ||= {}
    {
      controller: data['controller'],
      action: data['action'],
      params: params,
      version: 'GEM',
      consumer: consumer
    }
  end

  def get_request_headers
    result = {}
    env.each do |k, v|
      if (k.to_s.start_with?('HTTP_') || k.to_s.start_with?('X-')) && !HEADERS_BLACKLIST.include?(k) && !v.blank?
        result[k] = v
      end
    end
    result
  end

  def response_body(response)
    if @headers['Content-Type'] == 'text/csv' ||
      @headers['Content-Type'] == 'application/pdf'
      return { raw: "* * * RESPONSE NOT SHOWN FOR #{@headers['Content-Type']} * * *" }
    end

    if request_type == 'api'
      if response.respond_to?(:body)
        JSON.parse(response.body) rescue { raw: "* * * Unable to parse JSON response for #{@headers['Content-Type']} * * *" }
      else
        response
      end
    else
      if @headers['Content-Type']&.downcase&.include?('application/json')
        if response.respond_to?(:body)
          JSON.parse(response.body) rescue { raw: "* * * Unable to parse JSON response for #{@headers['Content-Type']} * * *" }
        else
          { raw: "* * * RESPONSE NOT SHOWN * * *" }
        end
      else
        { raw: "* * * RESPONSE NOT SHOWN FOR #{@headers['Content-Type']} * * *" }
      end
    end
  end

  def set_consumer
    if !subject.blank?
      @consumer = [subject[:type].downcase, subject[:id]].join(':')
    elsif env["action_dispatch.request.parameters"].present?
      @consumer = env["action_dispatch.request.parameters"].fetch('_consumer', 'unknown')
    end
  end

  def set_request_type
    # TODO: maybe we should check some header instead
    if env['PATH_INFO'].match?(/.*\.(?:png|css|jpeg|ico|gif)/)
      @request_type = 'static_asset'
    elsif env['PATH_INFO'].match?(/^\/api\/v[0-9]+/)
      @request_type = 'api'
    elsif env['PATH_INFO'].include?('/sidekiq')
      @request_type = 'sidekiq'
    elsif env['PATH_INFO'].include?('/rails')
      @request_type = 'rails'
    else
      @request_type = 'browser'
    end
  end

  def set_subject
    @subject = env["rack.session"].fetch('current_subject', {}).with_indifferent_access
    if @subject.blank?
      @subject = env["rack.session"].fetch(:current_subject, {}).with_indifferent_access
    end
  end

  def trackable?
    !%w[static_asset sidekiq rails].include?(request_type)
  end
end
