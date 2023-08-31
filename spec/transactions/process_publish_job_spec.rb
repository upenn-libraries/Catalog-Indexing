# frozen_string_literal: true

describe ProcessPublishJob do
  include FixtureHelpers

  let(:transaction) { described_class.new }
  let(:sftp_client) { instance_double Sftp::Client }

  before do
    allow(sftp_client).to receive(:download_all).and_return(sftp_files)
    allow(Sftp::Client).to receive(:new).and_return(sftp_client)
  end

  describe '#call' do
    context 'with valid webhook response body' do
      let(:webhook_response) { json_fixture 'job_end_success' }

      let(:sftp_files) do
        [Sftp::File.new('all_ub_ah_b_2023090100_12345678900000_new_001.xml.tar.gz')]
      end

      it 'succeeds and enqueues processing jobs for each SFTP file' do
        outcome = transaction.call(webhook_body: webhook_response)
        expect(outcome).to be_success
        expect(ProcessBulkFileJob.jobs.count).to eq sftp_files.count
      end
    end
  end
end
