class Injest::Writer
  include Singleton

  attr_reader :configuration, :http_client

  def append(data, sync: false)
    case configuration.strategy
    when 'push', 'http'
      if sync
        http_client.push(data)
      else
        Injest::Worker.perform_async(data)
      end
    
    when 'stdout'
      print(data)

    when 'null'
      # Do nothing
    else
      # Do nothing
    end
  end

  private
  def initialize
    @configuration = Injest::Configuration.instance
    @http_client = Injest::HttpClient.new(configuration)
  end

  def print(data)
    puts "=== Injest output ==="
    if data[:log_type] != 'audit'
      data.each do |k, v|
        if v.is_a?(Hash)
          puts "  - #{k}:"
          v.each do |k1, v1|
            puts "    - #{k1}: #{v1}"
          end
        else
          puts "  - #{k}: #{v}"
        end
      end
      return
    end

    puts "#{data[:request][:method]} #{data[:request][:path]} @ #{data[:human_time]} -- Request #{data[:request_id]}"
    puts ''
    puts "Subject"
    puts "  " + data[:request][:subject].inspect
    puts ''
    puts 'Context'
    puts "  " + data[:request][:context].inspect
    puts ''
    puts "Headers"
    data[:request][:headers].each do |k, v|
      puts "  - #{k}: #{v}"
    end
    puts ''
    puts "Response: #{data[:response][:status]}"
    puts data[:response][:body].inspect
  end
end