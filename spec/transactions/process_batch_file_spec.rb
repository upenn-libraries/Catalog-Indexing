# frozen_string_literal: true

describe ProcessBatchFile do
  let(:transaction) { described_class.new }

  describe '#call' do
    let(:outcome) { transaction.call(batch_file_id: batch_file.id, commit: true) }

    context 'with a bad BatchFile ID' do
      let(:batch_file) { instance_double(BatchFile) }

      before { allow(batch_file).to receive(:id).and_return(1) }

      it 'returns a Failure monad with the appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include 'record with ID 1 does not exist'
      end
    end

    context 'with invalid BatchFile status' do
      let(:batch_file) { create(:batch_file, :in_progress) }

      it 'returns a Failure monad with the appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include "BatchFile with ID #{batch_file.id} is in #{batch_file.status} state"
      end
    end

    context 'with a BatchFile that has no corresponding file on the filesystem' do
      let(:batch_file) { create(:batch_file) }

      it 'returns a Failure monad with the appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include "expects a file present at #{batch_file.path}"
      end
    end

    context 'with a problem during file decompression' do
      let(:batch_file) { create(:batch_file, :with_empty_file) }

      it 'returns a Failure monad with the appropriate message' do
        expect(outcome).to be_failure
        expect(outcome.failure).to include 'Problem decompressing BatchFile'
      end
    end

    context 'with indexing performed' do
      let(:collection) { Solr::Config.new.collection_name }
      let(:batch_file) do
        create(:batch_file, :with_two_record_file,
               alma_export: create(:alma_export, target_collections: [collection]))
      end
      let(:solr_query_client) { Solr::QueryClient.new(collection: collection) }

      before do
        solr_query_client.delete_all
        solr_query_client.commit
      end

      after do
        solr_query_client.delete_all
        solr_query_client.commit
      end

      it 'writes records to the index' do
        expect(outcome).to be_success
        solr_response = solr_query_client.get(params: { q: '*:*' })
        expect(solr_response['response']['numFound']).to eq 2
      end
    end
  end
end
