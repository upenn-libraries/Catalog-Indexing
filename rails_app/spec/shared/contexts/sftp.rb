# frozen_string_literal: true

# Stub SFTP connection to return files.
shared_context 'with sftp files available' do
  let(:sftp_client) { instance_double Sftp::Client }
  let(:sftp_files) { [Sftp::File.new('AllTitles_Find_50746714710003681_20240716_010743[039]_new_1.tar.gz')] }

  before do
    allow(sftp_client).to receive(:files).and_return(sftp_files)
    allow(sftp_client).to receive(:close_channel)
    allow(Sftp::Client).to receive(:new).and_return(sftp_client)
    downloader = instance_double(Net::SFTP::Operations::Download)
    allow(sftp_client).to receive(:download).and_return(downloader)
    allow(downloader).to receive(:wait).and_return(downloader)
  end
end

shared_context 'with incremental sftp files available' do
  let(:sftp_client) { instance_double Sftp::Client }
  let(:sftp_files) do
    [Sftp::File.new('AllTitles_Find_50746714710003681_20240716_010743[039]_new_1.tar.gz'),
     delete_file]
  end
  let(:delete_file) { instance_double(Sftp::File) }

  before do
    allow(sftp_client).to receive(:files).and_return(sftp_files)
    allow(sftp_client).to receive(:close_channel)
    allow(Sftp::Client).to receive(:new).and_return(sftp_client)
    downloader = instance_double(Net::SFTP::Operations::Download)
    allow(sftp_client).to receive(:download).and_return(downloader)
    allow(downloader).to receive(:wait).and_return(downloader)
    allow(delete_file).to receive(:local_path).and_return(
      Rails.root.join(fixture_paths.first, 'files', 'delete.tar.gz')
    )
    allow(delete_file).to receive(:name).and_return(
      'AllTitles_Find_50746714710003681_20240716_010743[039]_delete.tar.gz'
    )
  end
end
