# frozen_string_literal: true

require_relative 'concerns/statuses'

describe BatchFile do
  let(:batch_file) { create(:batch_file) }

  it_behaves_like 'statuses'

  it 'has one AlmaExport' do
    expect(batch_file.alma_export).to be_a AlmaExport
  end

  it 'requires a path' do
    file = build(:batch_file, path: nil)
    expect(file.valid?).to be false
    expect(file.errors[:path].join).to include "can't be blank"
  end

  it 'can have multiple error messages' do
    messages = %w[One Two]
    file = build(:batch_file, error_messages: messages)
    expect(file.error_messages).to eq messages
  end
end
