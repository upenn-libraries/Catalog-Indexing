# frozen_string_literal: true

# Stub SFTP connection to return files.
shared_context 'with sftp files available' do
  let(:sftp_client) { instance_double Sftp::Client }
  let(:sftp_files) { [Sftp::File.new('all_ub_ah_b_2023090100_12345678900000_new_001.xml.tar.gz')] }

  before do
    allow(sftp_client).to receive(:files).and_return(sftp_files)
    allow(sftp_client).to receive(:close_channel)
    allow(Sftp::Client).to receive(:new).and_return(sftp_client)
    downloader = instance_double(Net::SFTP::Operations::Download)
    allow(sftp_client).to receive(:download).and_return(downloader)
    allow(downloader).to receive(:wait).and_return(downloader)
  end
end
