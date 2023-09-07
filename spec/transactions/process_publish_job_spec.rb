# frozen_string_literal: true

describe ProcessPublishJob do
  include FixtureHelpers

  let(:transaction) { described_class.new }
  let(:sftp_client) { instance_double Sftp::Client }

  before do
    allow(sftp_client).to receive(:files).and_return(sftp_files)
    allow(Sftp::Client).to receive(:new).and_return(sftp_client)
  end

  after do
    Sidekiq::Worker.clear_all
  end

  describe '#call' do
    context 'with valid webhook response body' do
      let(:sftp_files) do
        [Sftp::File.new('all_ub_ah_b_2023090100_12345678900000_new_001.xml.tar.gz')]
      end
      let(:outcome) { transaction.call(webhook_body: json_fixture('job_end_success')) }

      before do
        downloader = instance_double(Net::SFTP::Operations::Download)
        allow(sftp_client).to receive(:download).and_return(downloader)
        allow(downloader).to receive(:wait).and_return(downloader)
      end

      it 'is successful' do
        expect(outcome).to be_success
      end

      it 'enqueues the right number of ProcessBatchFileJobs' do
        expect { outcome }.to change { ProcessBatchFileJob.jobs.count }.by sftp_files.count
      end

      it 'creates BatchFiles' do
        publish_job = outcome.success[:publish_job]
        expect(publish_job.batch_files.count).to eq sftp_files.count
      end

      it 'set the right attributes on the PublishJob' do
        publish_job = outcome.success[:publish_job]
        expect(publish_job.status).to eq Statuses::IN_PROGRESS
        expect(publish_job.started_at).to be_present
      end
    end

    context 'with bad webhook response' do
      let(:webhook_response) { 'bad' }
      let(:sftp_files) { [] }

      it 'returns a failure monad with appropriate message' do
        outcome = transaction.call webhook_body: webhook_response
        expect(outcome).to be_failure
        expect(outcome.failure).to include('Problem parsing webhook response')
      end
    end

    context 'with no files matching on SFTP server' do
      let(:webhook_response) { json_fixture 'job_end_success' }
      let(:sftp_files) { [] }

      it 'returns a failure monad with appropriate message' do
        outcome = transaction.call webhook_body: webhook_response
        expect(outcome).to be_failure
        expect(outcome.failure).to include('No files downloaded')
      end
    end

    context 'with an unexpected SFTP error' do
      let(:webhook_response) { json_fixture 'job_end_success' }
      let(:sftp_files) { ['dummy_file'] }

      before do
        allow(sftp_client).to receive(:download).and_raise Sftp::Client::Error
      end

      it 'returns a failure monad with appropriate message' do
        outcome = transaction.call webhook_body: webhook_response
        expect(outcome).to be_failure
        expect(outcome.failure).to include('Problem processing SFTP file')
      end
    end
  end
end
