# frozen_string_literal: true

describe ProcessAlmaExport do
  include FixtureHelpers

  let(:transaction) { described_class.new }

  after do
    Sidekiq::Worker.clear_all
  end

  describe '#call' do
    let(:alma_export) { create(:alma_export, webhook_body: JSON.parse(json_fixture('job_end_success'))) }
    let(:sftp_client) { instance_double Sftp::Client }
    let(:sftp_files) { [] }
    let(:outcome) { transaction.call(alma_export_id: alma_export.id) }

    before do
      allow(sftp_client).to receive(:files).and_return(sftp_files)
      allow(Sftp::Client).to receive(:new).and_return(sftp_client)
    end

    context 'with valid webhook response body' do
      let(:sftp_files) do
        [Sftp::File.new('all_ub_ah_b_2023090100_12345678900000_new_001.xml.tar.gz')]
      end

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
        alma_export = outcome.success[:alma_export]
        expect(alma_export.batch_files.count).to eq sftp_files.count
      end

      it 'set the right attributes on the AlmaExport' do
        alma_export = outcome.success[:alma_export]
        expect(alma_export.status).to eq Statuses::IN_PROGRESS
        expect(alma_export.started_at).to be_present
      end
    end

    context 'with a bad AlmaExport identifier' do
      before do
        allow(AlmaExport).to receive(:find).and_raise ActiveRecord::RecordNotFound
      end

      it 'returns a failure monad with appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include('does not exist')
      end
    end

    context 'with a AlmaExport not in PENDING status' do
      let(:alma_export) do
        create(:alma_export, status: Statuses::IN_PROGRESS, webhook_body: JSON.parse(json_fixture('job_end_success')))
      end

      it 'returns a failure monad with appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include("must be in 'pending' state")
      end
    end

    context 'with no files matching on SFTP server' do
      it 'returns a failure monad with appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include('No files downloaded')
      end
    end

    context 'with an unexpected SFTP error' do
      let(:sftp_files) { ['dummy_file'] }

      before do
        allow(sftp_client).to receive(:download).and_raise Sftp::Client::Error
      end

      it 'returns a failure monad with appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include('Problem processing SFTP file')
      end
    end
  end

  describe '#files_matching_regex' do
    let(:files) do
      [
        '.', '..', # returned by dir.entries command, ignore
        'prefix_2023010100_123456789_new_1.xml.tar.gz',
        'prefix_2023010100_123456789_new_23.xml.tar.gz',
        'prefix_2023010100_123456789_new_900.xml.tar.gz',
        'prefix_2023010100_123456789_new_1.zip', # wrong extension
        'prefix_2023010100_555555555_new_1.xml.tar.gz' # wrong job id
      ]
    end

    it 'can be used to select only the desired files' do
      regex = transaction.files_matching_regex('123456789')
      expect(files.grep(regex)).to eq %w[prefix_2023010100_123456789_new_1.xml.tar.gz
                                         prefix_2023010100_123456789_new_23.xml.tar.gz
                                         prefix_2023010100_123456789_new_900.xml.tar.gz]
    end

    it 'returns no files if a blank parameter is provided' do
      regex = transaction.files_matching_regex(nil)
      expect(files.grep(regex)).to be_empty
    end
  end
end
