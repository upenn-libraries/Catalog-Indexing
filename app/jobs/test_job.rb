# frozen_string_literal: true

# Sample job to test Sidekiq config
class TestJob
  include Sidekiq::Job

  def perform(*args)
    p "Job starting with args #{args}"
    sleep 5
    p 'Job complete'
  end
end
