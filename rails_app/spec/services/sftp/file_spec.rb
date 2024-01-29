# frozen_string_literal: true

describe Sftp::File do
  let(:file_name) { 'test.xml.tar.gz' }
  let(:file) { described_class.new(file_name) }

  describe '#initialize' do
    it 'sets the name attribute' do
      expect(file.name).to eq(file_name)
    end
  end

  describe '#remote_path' do
    it 'returns expected remote path' do
      expect(file.remote_path).to eq("#{Settings.sftp.root}/#{file_name}")
    end
  end

  describe '#local_path' do
    it 'returns expected local path' do
      expect(file.local_path).to eq(Rails.root.join('storage', file_name).to_s)
    end
  end

  describe '#downloaded?' do
    it 'returns false when file does not exist in local storage' do
      expect(file).not_to be_downloaded
    end

    it 'returns true when file exists in local storage' do
      Tempfile.create(file_name, Rails.root.join('storage')) do |tempfile|
        file = described_class.new(File.basename(tempfile.path))
        expect(file).to be_downloaded
      end
    end
  end
end
