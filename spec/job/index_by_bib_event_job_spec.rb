# frozen_string_literal: true

describe IndexByBibEventJob do
  include FixtureHelpers

  let(:sample_mmsid) { '9979201969103681' }
  let(:marcxml) { marc_fixture sample_mmsid }

  it_behaves_like 'TransactionJob' do
    let(:args) { [marcxml] }
  end
end
