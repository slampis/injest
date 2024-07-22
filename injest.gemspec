Gem::Specification.new do |s|
  s.name        = 'injest-client'
  s.version     = '0.1.7'
  s.summary     = "Injest client"
  s.description = "Injest client"
  s.authors     = ["Stefano Lampis"]
  s.email       = 'me@stefanolampis.com'
  # s.files       = ["lib/injest.rb"]
  s.files       = Dir["lib/**/*"]
  s.homepage    = 'https://rubygems.org/gems/slampis-injest-client'
  s.license     = 'MIT'

  s.add_dependency 'sidekiq'
  
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rack'
end