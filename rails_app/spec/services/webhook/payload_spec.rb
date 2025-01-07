# frozen_string_literal: true

describe Webhook::Payload do
  include FixtureHelpers

  describe '.build' do
    let(:object) { described_class.build payload: payload }

    context 'with a job end payload' do
      let(:payload) { JSON.parse json_fixture('job_end_success_incremental', :webhooks) }

      it 'returns a Webhook::Job instance' do
        expect(object).to be_an_instance_of(Webhook::Job)
      end
    end

    context 'with a bib payload' do
      let(:payload) { JSON.parse json_fixture('bib_created', :webhooks) }

      it 'returns a Webhook::Bib instance' do
        expect(object).to be_an_instance_of(Webhook::Bib)
      end
    end
  end

  describe '#action' do
    let(:payload) { { 'action' => 'ACTION' } }

    it 'returns action value' do
      expect(described_class.new(data: payload).action).to eq 'ACTION'
    end
  end
end
