# frozen_string_literal: true

require_relative 'transaction_job_spec'

describe IndexByIdentifiersJob do
  include FixtureHelpers
  include_context 'with successful Alma request to get XML from IDs'

  let(:identifiers) { ['9979201969103681'] }

  it_behaves_like 'TransactionJob' do
    let(:args) { [identifiers] }
  end
end
