class Injest::Configuration
  include Singleton

  attr_reader :strategy,
              :strategies,
              :injest_root,
              :injest_token,
              :injest_client

  private

  def initialize
    @strategy = ENV.fetch('INJEST_STRATEGY')
    set_strategies

    if @strategies.include?('push') || @strategies.include?('http')
      @injest_root = ENV.fetch('INJEST_ROOT')
      @injest_token = ENV.fetch('INJEST_JWT')
    end

    @injest_client = ENV.fetch('INJEST_CLIENT', nil)
  end

  def set_strategies
    raw = @strategy
    if raw == nil || raw == ''
      @strategies = ['null']
    else
      @strategies = raw.split(',')
    end
  end
end