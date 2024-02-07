# frozen_string_literal: true

# credit to PSU's Solr::Admin specs
# https://github.com/psu-libraries/scholarsphere/blob/develop/spec/lib/scholarsphere/solr_admin_spec.rb
describe Solr::Admin do
  let(:admin) { described_class.new }

  describe '.reset' do
    let(:stubbed_admin) { instance_spy(described_class) }

    before do
      allow(described_class).to receive(:new).and_return(stubbed_admin)
      described_class.reset
    end

    it 'deletes everything' do
      expect(stubbed_admin).to have_received(:delete_all_collections)
    end

    it 'recreates the collection' do
      expect(stubbed_admin).to have_received(:create_collection)
    end
  end

  describe '#all_collections' do
    it 'returns list of all collections' do
      expect(admin.all_collections).to include 'catalog-indexing-test'
    end
  end

  describe '#create_collection' do
    after { admin.delete_collection(name: 'sample_collection') }

    it 'can create a collection' do
      expect(admin.create_collection(name: 'sample_collection')).to be_nil
    end
  end

  describe('#delete_collection') do
    before { admin.create_collection(name: 'sample_collection') }

    it 'can delete a collection' do
      expect(admin.delete_collection(name: 'sample_collection')).to be_nil
    end
  end

  describe('#delete_all_collections') do
    before do
      allow(admin).to receive(:collections).and_return(%w[sample_collection another_collection])
      allow(admin).to receive(:delete_collection).with(name: 'sample_collection').and_return(nil)
      allow(admin).to receive(:delete_collection).with(name: 'another_collection').and_return(nil)
    end

    it 'deletes all the collections' do
      expect(admin.delete_all_collections).to contain_exactly(nil, nil)
      expect(admin).to have_received(:delete_collection).twice
    end
  end

  describe('#modify_collection') do
    it 'modifies a collection' do
      expect(admin.modify_collection).to be_nil
    end
  end

  context 'when receiving a bad response' do
    it 'raises a Solr::Admin::Error with a specific error message if response can be parsed as JSON' do
      expect { admin.create_collection(name: nil, configset: nil) }.to raise_error(
        Solr::Admin::Error, /Request to Solr failed with code 400: Invalid collection: \[\]/
      )
    end

    it "raises a Solr::Admin::Error with a generic message if response can't be parsed as JSON" do
      allow(JSON).to receive(:parse).and_raise(JSON::ParserError)
      expect {
        admin.create_collection(name: nil, configset: nil)
      }.to raise_error(Solr::Admin::Error, /Request to Solr failed\./)
    end
  end
end
