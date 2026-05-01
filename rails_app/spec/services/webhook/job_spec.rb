# frozen_string_literal: true

describe Webhook::Job do
  include FixtureHelpers

  subject { described_class.new data: payload }

  context 'with an uninteresting job (not publishing related)' do
    let(:payload) { JSON.parse json_fixture('job_end_uninteresting', :webhooks) }

    it { is_expected.to have_attributes id: '1234567891234567', job_name: 'An Uninteresting Job' }
    it { is_expected.not_to be_successful_publishing_job }
    it { is_expected.not_to be_full_publish }
  end

  context 'with a full publishing job' do
    let(:payload) { JSON.parse json_fixture('job_end_success_full_publish', :webhooks) }

    it { is_expected.to have_attributes job_status: 'COMPLETED_SUCCESS', job_counter_updated_records: '0' }
    it { is_expected.to be_successful_publishing_job }
    it { is_expected.to be_full_publish }
  end

  context 'with an incremental publishing job' do
    let(:payload) { JSON.parse json_fixture('job_end_mixed_incremental', :webhooks) }

    it { is_expected.to have_attributes job_status: 'COMPLETED_FAILED', job_counter_deleted_records: '5' }
    it { is_expected.to be_successful_publishing_job }
    it { is_expected.not_to be_full_publish }
  end
end
