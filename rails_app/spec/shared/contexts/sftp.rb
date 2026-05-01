# frozen_string_literal: true

# Stub SFTP connection to return files.
shared_context 'with sftp files available' do
  let(:sftp_client) { instance_double Sftp::Client }
  let(:sftp_files) { [Sftp::File.new('AllTitles_Find_1234567891234567_20240716_010743[039]_new_1.tar.gz')] }

  before do
    allow(sftp_client).to receive(:close_channel)
    allow(Sftp::Client).to receive(:new).and_return(sftp_client)
    downloader = instance_double(Net::SFTP::Operations::Download)
    allow(sftp_client).to receive_messages(files: sftp_files, download: downloader)
    allow(downloader).to receive(:wait).and_return(downloader)
  end
end

shared_context 'with incremental sftp files available' do
  let(:sftp_client) { instance_double Sftp::Client }
  let(:sftp_files) do
    [Sftp::File.new('AllTitles_Find_1234567891234567_20240716_010743[039]_new_1.tar.gz'),
     delete_file]
  end
  let(:delete_file) { instance_double(Sftp::File) }

  before do
    allow(sftp_client).to receive(:close_channel)
    allow(Sftp::Client).to receive(:new).and_return(sftp_client)
    downloader = instance_double(Net::SFTP::Operations::Download)
    allow(sftp_client).to receive_messages(files: sftp_files, download: downloader)
    allow(downloader).to receive(:wait).and_return(downloader)
    allow(delete_file).to receive_messages(local_path: Rails.root.join(fixture_paths.first, 'files', 'delete.tar.gz'),
                                           name: 'AllTitles_Find_1234567891234567_20240716_010743[039]_delete.tar.gz')
  end
end
