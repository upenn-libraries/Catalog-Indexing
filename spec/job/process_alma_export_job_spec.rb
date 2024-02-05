# frozen_string_literal: true

require_relative 'transaction_job_spec'

describe ProcessAlmaExportJob do
  include FixtureHelpers

  let(:alma_export_id) { '1234' }

  it_behaves_like 'TransactionJob' do
    let(:args) { [alma_export_id] }
  end
end
