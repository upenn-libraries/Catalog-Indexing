# frozen_string_literal: true

describe Webhook::Bib do
  include FixtureHelpers

  subject { described_class.new data: payload }

  context 'with a bib created' do
    let(:payload) { JSON.parse json_fixture('bib_created', :webhooks) }

    it { is_expected.to have_attributes id: '7120811384122420557', event: 'BIB_CREATED' }
    it { is_expected.not_to be_suppress_from_publishing }
    it { is_expected.not_to be_suppress_from_external_search }
    it { is_expected.not_to be_suppress_from_discovery }
  end

  context 'with a suppressed bib created' do
    let(:payload) { JSON.parse json_fixture('bib_created_suppressed', :webhooks) }

    it { is_expected.to be_suppress_from_publishing }
    it { is_expected.not_to be_suppress_from_external_search }
    it { is_expected.to be_suppress_from_discovery }
  end

  context 'with a bib updated' do
    let(:payload) { JSON.parse json_fixture('bib_updated', :webhooks) }

    it { is_expected.to have_attributes event: 'BIB_UPDATED' }
    it { is_expected.not_to be_suppress_from_publishing }
    it { is_expected.not_to be_suppress_from_external_search }
    it { is_expected.not_to be_suppress_from_discovery }
  end

  context 'with a bib deleted' do
    let(:payload) { JSON.parse json_fixture('bib_deleted', :webhooks) }

    it { is_expected.to have_attributes event: 'BIB_DELETED' }
    it { is_expected.not_to be_suppress_from_publishing }
    it { is_expected.not_to be_suppress_from_external_search }
    it { is_expected.not_to be_suppress_from_discovery }
  end
end
