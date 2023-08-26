# frozen_string_literal: true

require_relative 'concerns/statuses'

describe BatchFile do
  let(:batch_file) { create(:batch_file) }

  it_behaves_like 'statuses'

  it 'has one PublishJob' do
    expect(batch_file.publish_job).to be_a PublishJob
  end

  it 'requires a path' do
    file = build(:batch_file, path: nil)
    expect(file.valid?).to be false
    expect(file.errors[:path].join).to include "can't be blank"
  end
end
