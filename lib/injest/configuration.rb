class Injest::Configuration
  include Singleton

  attr_reader :strategy, 
    :injest_root, :injest_token, :injest_client

  private
  def initialize
    @strategy = ENV.fetch('INJEST_STRATEGY', 'stdout')

    if strategy == 'http' || strategy == 'push'
      @injest_root = ENV.fetch('INJEST_ROOT')
      @injest_token = ENV.fetch('INJEST_JWT')
    end
    
    @injest_client = ENV.fetch('INJEST_CLIENT', nil)
  end
end