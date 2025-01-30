# frozen_string_literal: true

shared_examples_for 'job_details' do
  let(:alma_export) { described_class.new(webhook_body: webhook_body) }
  let(:webhook_body) do
    JSON.parse(json_fixture('job_end_success_full_publish', :webhooks))
  end

  describe '#job_started_at' do
    it 'returns timestamp' do
      expect(alma_export.job_started_at).to be_a Time
    end
  end

  describe '#job_ended_at' do
    it 'returns timestamp' do
      expect(alma_export.job_ended_at).to be_a Time
    end
  end

  describe '#job_duration' do
    it 'returns duration' do
      expect(alma_export.job_duration).to be_a String
    end
  end

  describe '#new_records' do
    it 'returns new record count' do
      expect(alma_export.new_records).to be_a String
    end
  end

  describe '#updated_records' do
    it 'returns updated record count' do
      expect(alma_export.updated_records).to be_a String
    end
  end

  describe '#deleted_records' do
    it 'returns deleted record count' do
      expect(alma_export.deleted_records).to be_a String
    end
  end
end
