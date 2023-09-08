# frozen_string_literal: true

require_relative 'concerns/statuses'

describe AlmaExport do
  let(:alma_export) { create(:alma_export_with_files, files_count: 2) }

  it_behaves_like 'statuses'

  it 'has many BatchFiles' do
    expect(alma_export.batch_files.first).to be_a BatchFile
    expect(alma_export.batch_files.length).to eq 2
  end

  it 'requires a valid status' do
    export = build(:alma_export, status: 'single')
    expect(export.valid?).to be false
    expect(export.errors[:status].join).to include 'is not included'
  end

  it 'requires a valid source' do
    export = build(:alma_export, alma_source: 'voyager')
    expect(export.valid?).to be false
    expect(export.errors[:alma_source].join).to include 'is not included'
  end

  it 'requires a webhook_body' do
    export = build(:alma_export, webhook_body: nil)
    expect(export.valid?).to be false
    expect(export.errors[:webhook_body].join).to include "can't be blank"
  end

  it 'requires a full? value' do
    export = build(:alma_export, full: nil)
    expect(export.valid?).to be false
    expect(export.errors[:full].join).to include "can't be blank"
  end

  it 'can have multiple target_collection values' do
    target_collections = %w[staging production]
    export = create(:alma_export, target_collections: target_collections)
    expect(export.valid?).to be true
    expect(export.target_collections).to eq target_collections
  end
end
