class Injest::Worker
  include Sidekiq::Worker
  def perform(data)
    Injest::Writer.instance.append(data, sync: true)
  end
end