# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

RSpec.describe TestJob, type: :job do
  it 'can be enqueued' do
    expect {
      described_class.perform_async('123')
    }.to change(described_class.jobs, :size).by(1)
  end

  it 'is executed' do
    Sidekiq::Testing.inline! do
      expect {
        described_class.perform_async('123')
      }.to output(a_string_including('Job complete')).to_stdout
    end
  end
end
