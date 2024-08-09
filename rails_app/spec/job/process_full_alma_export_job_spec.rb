# frozen_string_literal: true

describe ProcessFullAlmaExportJob do
  include FixtureHelpers

  let(:alma_export_id) { '1234' }

  it_behaves_like 'TransactionJob' do
    let(:args) { [alma_export_id] }
  end
end
