# frozen_string_literal: true

describe IndexByBibEventJob do
  include FixtureHelpers
  include SolrHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:marcxml) { marc_fixture sample_mmsid }

  before do
    allow(ConfigItem).to receive(:value_for).with(:webhook_target_collections).and_return(Array.wrap(test_collection))
  end

  it_behaves_like 'TransactionJob' do
    let(:args) { [marcxml] }
  end
end
