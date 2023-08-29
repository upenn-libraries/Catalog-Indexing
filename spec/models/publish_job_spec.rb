# frozen_string_literal: true

require_relative 'concerns/statuses'

describe PublishJob do
  let(:publish_job) { create(:publish_job_with_files, files_count: 2) }

  it_behaves_like 'statuses'

  it 'has many BatchFiles' do
    expect(publish_job.batch_files.first).to be_a BatchFile
    expect(publish_job.batch_files.length).to eq 2
  end

  it 'requires a valid status' do
    publish = build(:publish_job, status: 'single')
    expect(publish.valid?).to be false
    expect(publish.errors[:status].join).to include 'is not included'
  end

  it 'requires a valid source' do
    publish = build(:publish_job, alma_source: 'voyager')
    expect(publish.valid?).to be false
    expect(publish.errors[:alma_source].join).to include 'is not included'
  end

  it 'requires a full? value' do
    publish = build(:publish_job, full: nil)
    expect(publish.valid?).to be false
    expect(publish.errors[:full].join).to include "can't be blank"
  end

  it 'can have multiple target_collection values' do
    target_collections = %w[staging production]
    publish = create(:publish_job, target_collections: target_collections)
    expect(publish.valid?).to be true
    expect(publish.target_collections).to eq target_collections
  end
end
