# frozen_string_literal: true

require_relative 'concerns/statuses'
require_relative 'concerns/job_details'

describe AlmaExport do
  include FixtureHelpers

  let(:alma_export) { create(:alma_export_with_files, files_count: 2) }

  it_behaves_like 'statuses'
  it_behaves_like 'job_details'

  it 'has many BatchFiles' do
    expect(alma_export.batch_files.first).to be_a BatchFile
    expect(alma_export.batch_files.length).to eq 2
  end

  it 'requires a valid status' do
    export = build(:alma_export, status: 'single')
    expect(export.valid?).to be false
    expect(export.errors[:status].join).to include 'is not included'
  end

  it 'requires a job_identifier' do
    export = build(:alma_export, job_identifier: nil)
    expect(export.valid?).to be false
    expect(export.errors[:job_identifier].join).to include "can't be blank"
  end

  it 'requires a valid source' do
    export = build(:alma_export, alma_source: 'voyager')
    expect(export.valid?).to be false
    expect(export.errors[:alma_source].join).to include 'is not included'
  end

  it 'requires a full? value' do
    export = build(:alma_export, full: nil)
    expect(export.valid?).to be false
    expect(export.errors[:full].join).to include 'is not included in the list'
  end

  it 'can have multiple target_collection values' do
    target_collections = %w[staging production]
    export = create(:alma_export, target_collections: target_collections)
    expect(export.valid?).to be true
    expect(export.target_collections).to eq target_collections
  end

  describe '.create_full!' do
    context 'with valid parameters' do
      let(:export) { described_class.create_full!(job_id: '123456') }

      it 'returns an alma_export with the expected attributes' do
        expect(export.job_identifier).to eq '123456'
        expect(export.full).to be true
      end
    end

    context 'with no job_id parameter' do
      it 'raises an exception' do
        expect { described_class.create_full!(job_id: nil) }.to(
          raise_error(ActiveRecord::RecordInvalid, "Validation failed: Job identifier can't be blank")
        )
      end
    end
  end

  describe '.create_incremental!' do
    context 'with valid parameters' do
      let(:export) { described_class.create_incremental!(job_id: '123456') }

      it 'returns an alma_export with the expected attributes' do
        expect(export.job_identifier).to eq '123456'
        expect(export.full).to be false
      end
    end

    context 'with no job_id parameter' do
      it 'raises an exception' do
        expect { described_class.create_full!(job_id: nil) }.to(
          raise_error(ActiveRecord::RecordInvalid, "Validation failed: Job identifier can't be blank")
        )
      end
    end
  end

  describe '#process!' do
    context 'with a full AlmaExport in PENDING status' do
      let(:alma_export) { create(:alma_export, :pending) }

      it 'enqueues a full processing job' do
        expect {
          alma_export.process!
        }.to change { ProcessFullAlmaExportJob.jobs.count }.by 1
      end
    end

    context 'with an incremental AlmaExport in PENDING status' do
      let(:alma_export) { create(:alma_export, :incremental, :pending) }

      it 'enqueues an incremental processing job' do
        expect {
          alma_export.process!
        }.to change { ProcessIncrementalAlmaExportJob.jobs.count }.by 1
      end
    end

    context 'with an AlmaExport not in PENDING status' do
      let(:alma_export) { create(:alma_export, :in_progress) }

      it 'raises an exception' do
        expect { alma_export.process! }.to(
          raise_error(AlmaExport::InvalidStatusError, /AlmaExport ##{alma_export.id} is in #{alma_export.status} state/)
        )
      end
    end

    context 'with inline true' do
      let(:alma_export) { create(:alma_export, :pending) }
      let(:transaction) { instance_double ProcessFullAlmaExport }

      before do
        allow(transaction).to receive(:call).and_return(Dry::Monads::Success)
        allow(ProcessFullAlmaExport).to receive(:new).and_return(transaction)
      end

      it 'runs the appropriate processing transaction' do
        alma_export.process!(inline: true)
        expect(transaction).to have_received(:call).with(alma_export_id: alma_export.id)
      end
    end
  end

  describe '#set_completion_status!' do
    let(:alma_export) { create(:alma_export, *traits) }

    before { alma_export.set_completion_status! }

    context 'with a radically failed AlmaExport' do
      let(:traits) { [:with_files_all_failed] }

      it 'sets a status of FAILED' do
        expect(alma_export.status).to eq Statuses::FAILED
        expect(alma_export.completed_at).to be_present
      end
    end

    context 'with a radically successful AlmaExport' do
      let(:traits) { [:with_files_all_completed] }

      it 'sets a status of COMPLETED' do
        expect(alma_export.status).to eq Statuses::COMPLETED
        expect(alma_export.completed_at).to be_present
      end
    end

    context 'with an AlmaExport with mixed processing outcomes' do
      let(:traits) { [:with_files_some_failed] }

      it 'sets a status of COMPLETED WITH ERRORS' do
        expect(alma_export.status).to eq Statuses::COMPLETED_WITH_ERRORS
        expect(alma_export.completed_at).to be_present
      end
    end

    context 'with an AlmaExport with incomplete outcomes' do
      let(:traits) { [:with_files_all_incomplete] }

      it 'does not change the status or completed_at value' do
        expect(alma_export.status).to eq Statuses::PENDING
        expect(alma_export.completed_at).to be_nil
      end
    end
  end

  describe '#all_batch_files_finished?' do
    let(:alma_export) { create(:alma_export, *traits) }

    context 'with BatchFile records that are incomplete' do
      let(:traits) { [:with_files_all_incomplete] }

      it 'returns false' do
        expect(alma_export.all_batch_files_finished?).to be false
      end
    end

    context 'with a BatchFile record that are all finished' do
      let(:traits) { [:with_files_all_completed] }

      it 'returns true' do
        expect(alma_export.all_batch_files_finished?).to be true
      end
    end
  end
end
