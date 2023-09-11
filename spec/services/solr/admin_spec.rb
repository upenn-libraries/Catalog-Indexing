# frozen_string_literal: true

describe Solr::Admin do
  let(:admin) { described_class.new }

  describe '#all_collections' do
    it 'returns list of all collections' do
      expect(admin.all_collections).to contain_exactly('catalog-development', 'catalog-test')
    end
  end

  describe '#collection_exists?' do
    it 'returns true when a collection exists' do
      expect(admin).to be_collection_exists(name: 'catalog-test')
    end

    it 'returns false when a collection does not exist' do
      expect(admin).not_to be_collection_exists(name: 'catalog-does-not-exist')
    end
  end

  describe '#create_collection' do
    after { admin.delete_collection('sample_collection') }

    it 'can create a collection' do
      expect(admin.create_collection(name: 'sample_collection')).to be_nil
    end
  end

  describe('#delete_collection') do
    before { admin.create_collection(name: 'sample_collection') }

    it 'can delete a collection' do
      expect(admin.delete_collection('sample_collection')).to be_nil
    end
  end

  describe('#delete_all_collections') do
    before do
      allow(admin).to receive(:collections).and_return(%w[sample_collection another_collection])
      allow(admin).to receive(:delete_collection).with('sample_collection').and_return(nil)
      allow(admin).to receive(:delete_collection).with('another_collection').and_return(nil)
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

  describe '#zip_file' do
    it 'returns a zip file that we can read' do
      result = admin.zip_file
      contents = result.read
      expect(contents).to be_a(String)
      expect(contents).not_to be_empty
    end
  end
end
