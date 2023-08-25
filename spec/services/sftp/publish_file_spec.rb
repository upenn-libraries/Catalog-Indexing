# frozen_string_literal: true

describe Sftp::PublishFile do

  let(:file_name) { 'test.xml.tar.gz' }
  let(:publish_file) { described_class.new(file_name) }

  describe '#initialize' do
    it 'sets the name attribute' do
      expect(publish_file.name).to eq(file_name)
    end
  end

  describe '#remote_path' do
    it 'returns expected remote path' do
      expect(publish_file.remote_path).to eq("#{Sftp::Client::ROOT}/#{file_name}")
    end
  end

  describe '#local_path' do
    it 'returns expected local path' do
      expect(publish_file.local_path).to eq(Rails.root.join('storage', file_name).to_s)
    end
  end

  describe '#downloaded?' do
    it 'returns false when file does not exist in local storage' do
      expect(publish_file).not_to be_downloaded
    end

    it 'returns true when file exists in local storage' do
      publish_file.local_path(dir: 'spec/fixtures/alma_publish_file')
      expect(publish_file).to be_downloaded
    end
  end
end
