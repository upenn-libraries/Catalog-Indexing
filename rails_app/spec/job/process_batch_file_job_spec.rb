# frozen_string_literal: true

describe ProcessBatchFileJob do
  include FixtureHelpers

  let(:batch_file_id) { '1234' }

  it_behaves_like 'TransactionJob' do
    let(:args) { [batch_file_id] }
  end
end
