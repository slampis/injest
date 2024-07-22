require 'spec_helper'
describe Injest::Middleware do
  it 'some spec' do
    app = lambda { |env| [200, { 'content-type' => 'text/plain' }, ["Hello, World!"]] }
    env = Rack::MockRequest.env_for "/some/path", method: 'POST', 
      'action_dispatch.request.parameters' => { 'action' => 'action_name', 'controller' => 'foos', },
      'action_dispatch.request.request_parameters' => { 'id' => 1 }
    middleware = Injest::Middleware.new(app)
    middleware.call(env)

    puts env.inspect
    expect(1).to eq 1
  end
end