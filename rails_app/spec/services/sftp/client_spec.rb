# frozen_string_literal: true

describe Sftp::Client do
  let(:client) { described_class.new }
  let(:sftp_session) { instance_double(Net::SFTP::Session) }

  before do
    allow(Net::SFTP).to receive(:start).and_return(sftp_session)
  end

  describe '#files' do
    let(:sftp_dir) { instance_double(Net::SFTP::Operations::Dir) }
    let(:files) { [Sftp::File.new('test_file.txt')] }

    before do
      allow(sftp_session).to receive(:dir).and_return(sftp_dir)
      allow(sftp_dir).to receive(:entries).and_return(files)
    end

    it 'lists files in the remote directory' do
      client_files = client.files
      expect(client_files.collect(&:name)).to eq(files.collect(&:name))
    end

    it 'raises error when it fails to list files on the remote directory' do
      allow(sftp_session).to receive(:dir).and_raise(Net::SSH::ConnectionTimeout)
      expect { client.files }.to raise_error(
        Sftp::Client::Error,
        'Could not list files on the SFTP server: Net::SSH::ConnectionTimeout'
      )
    end
  end

  describe '#download' do
    let(:file) { Sftp::File.new('job_output_12345678_1.xml.tar.gz') }
    let(:sftp_downloader) { instance_double(Net::SFTP::Operations::Download) }

    before do
      allow(sftp_session).to receive(:download).and_return(sftp_downloader)
      allow(sftp_downloader).to receive(:wait).and_return(sftp_downloader)
    end

    it 'runs the Net::SFTP event loop to ensure the file downloads' do
      client.download(file)
      expect(sftp_session).to have_received(:download)
      expect(sftp_downloader).to have_received(:wait)
    end

    it "doesn't run the Net::SFTP event loop when wait parameter is false" do
      client.download(file, wait: false)
      expect(sftp_session).to have_received(:download)
      expect(sftp_downloader).not_to have_received(:wait)
    end

    it 'raises an error when it fails to download the file' do
      allow(sftp_session).to receive(:download).and_raise(Net::SFTP::Exception)
      expect { client.download(file) }.to raise_error(
        Sftp::Client::Error,
        'Could not download file from SFTP server: Net::SFTP::Exception'
      )
    end
  end

  describe '#delete' do
    let(:file) { Sftp::File.new('job_output_12345678_1.xml.tar.gz') }
    let(:sftp_request) { instance_double(Net::SFTP::Request) }

    before do
      allow(sftp_session).to receive(:remove).and_return(sftp_request)
      allow(sftp_request).to receive(:wait).and_return(sftp_request)
    end

    it 'deletes a file from remote directory' do
      client.delete(file)
      expect(sftp_session).to have_received(:remove)
      expect(sftp_request).to have_received(:wait)
    end

    it 'raises an error when it fails to delete file from remote directory' do
      allow(sftp_session).to receive(:remove).and_raise(Net::SFTP::Exception)
      expect { client.delete(file) }.to raise_error(
        Sftp::Client::Error,
        'Could not delete file on SFTP server: Net::SFTP::Exception'
      )
    end
  end

  describe '#sftp' do
    it 'starts an sftp session' do
      expect(client.sftp).to eq(sftp_session)
    end

    it 'raises an error when it fails to connect to sftp server' do
      allow(Net::SFTP).to receive(:start).and_raise(Net::SSH::Exception)
      expect { client.sftp }.to raise_error(Sftp::Client::Error,
                                            'Could not connect to SFTP server: Net::SSH::Exception')
    end
  end
end
