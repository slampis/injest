require 'net/http'
require 'json'

class Injest::HttpClient
  attr_reader :root_url,
              :push_url,
              :search_url,
              :jwt,
              :client_code
  def initialize(configuration)
    @root_url = configuration.injest_root
    @client_code = configuration.injest_client
    if client_code.nil? || client_code == ''
      @push_url = [root_url, 'api/v1/logs'].join('/')
    else
      @push_url = [root_url, 'api/v1/logs', client_code].join('/')
    end
    @search_url = [root_url, 'api/v1/logs/search'].join('/')
    @jwt = configuration.injest_token
  end

  # Push an audit log
  def audit(data)
    push data.merge(log_type: 'audit')
  end

  def search(page: 1, per: 20, **other)
    payload = {
      page: page,
      per: per,
      logs_search_form: {}
    }
    other.each do |k, v|
      payload[:logs_search_form][k] = v
    end

    post_http_request search_url, payload
  end

  # Push a log
  def push(data)
    data = data_as_hash(data)
    create_log(data)
  end

  def json(time:, severity:, data:,
           correlation_id: nil,
           request_id: nil,
           partition_key: nil,
           owner: nil,
           delta: nil)
    request_id ||= SecureRandom.uuid
    data = {
      request_id: request_id,
      correlation_id: correlation_id,
      time: time,
      human_time: Time.at(time).to_s,
      log_type: 'json',
      severity: severity,
      partition_key: partition_key,
      owner: owner,
      delta: delta,
      data: data_as_hash(data)
    }
    create_log data
  end

  def text(time:, severity:, message:,
           correlation_id: nil,
           request_id: nil,
           partition_key: nil,
           owner: nil,
           delta: nil)
    request_id ||= SecureRandom.uuid
    data = {
      request_id: request_id,
      correlation_id: correlation_id,
      time: time,
      human_time: Time.at(time).to_s,
      log_type: 'text',
      severity: severity,
      partition_key: partition_key,
      owner: owner,
      delta: delta,
      text: message
    }
    create_log data
  end

  def process_response!(response)
    case response.code
    when '200', '201'
      unless response.body.empty?
        JSON.parse(response.body)
      else
        {}
      end
    else
      data = JSON.parse(response.body) unless response.body.blank?
      puts "Endpoint replied with #{response.code} - #{data['error_code']}", data: data
      raise "Endpoint replied with #{response.code} - #{data['error_code']}", data: data
    end
  end

  private
  def create_log(data)
    return if ENV['INJEST_STRATEGY'] == 'null'

    if ENV['INJEST_STRATEGY'] == 'stdout'
      puts "== Injest STDOUT data =="
      # puts data.inspect
      print_log(data)
      return
    end

    post_http_request push_url, data
    # uri = URI.parse push_url
    # request = Net::HTTP::Post.new(uri)
    # request["Content-Type"] = "application/json"
    # request["Accept"] = "application/json"
    # request['Authorization'] = "Bearer #{jwt}"
    # case data
    # when String
    #   request.body = data
    # when Hash
    #   request.body = data.to_json
    # end
    # req_options = { use_ssl: uri.scheme == "https" }
    # response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    #   http.request(request)
    # end
    #
    # process_response!(response)
  end

  def post_http_request(url, data)
    uri = URI.parse url
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    request['Authorization'] = "Bearer #{jwt}"
    case data
    when String
      request.body = data
    when Hash
      request.body = data.to_json
    end
    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    process_response!(response)
  end

  def data_as_hash(data)
    case data
    when String
      JSON.parse(data)
    when Hash
      data
    end
  end

  def print_log(data)
    puts "LOGTYPE '#{data[:log_type]}'"
    if data[:log_type] != 'audit'
      puts data.inspect
      return
    end

    puts "#{data[:human_time]} - Request #{data[:request_id]}"
    puts "#{data[:request][:method]} #{data[:request][:path]}"
    puts ''
    puts "Subject"
    puts data[:request][:subject].inspect
    puts ''
    puts 'Context'
    puts data[:request][:context].inspect
    puts ''
    puts "Headers"
    data[:request][:headers].each do |k, v|
      puts "#{k}: #{v}"
    end
    puts ''
    puts "Response: #{data[:response][:status]}"
    puts data[:response][:body].inspect
  end
end