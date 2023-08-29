# frozen_string_literal: true

describe Sftp::Client do
  let(:client) { described_class.new }
  let(:sftp_session) { instance_double(Net::SFTP::Session) }

  before do
    allow(Net::SFTP).to receive(:start).and_return(sftp_session)
  end

  describe '#files' do
    let(:sftp_dir) { instance_double(Net::SFTP::Operations::Dir) }
    let(:files) do
      [
        instance_double(Net::SFTP::Protocol::V04::Name, name: 'test_file_1.xml.tar.gz'),
        instance_double(Net::SFTP::Protocol::V04::Name, name: 'test_file_2.xml.tar.gz')
      ]
    end

    before do
      allow(sftp_session).to receive(:dir).and_return(sftp_dir)
      allow(sftp_dir).to receive(:glob).and_return(files)
    end

    it 'lists files in the remote directory' do
      files = client.files(matching: '*.xml.tar.gz')
      expect(files.map(&:name)).to contain_exactly('test_file_1.xml.tar.gz', 'test_file_2.xml.tar.gz')
      expect(files).to be_all(Sftp::File)
    end

    it 'raises error when it fails to list files on the remote directory' do
      allow(sftp_session).to receive(:dir).and_raise(Net::SSH::ConnectionTimeout)
      expect { client.files(matching: '.xml.tar.gz') }.to raise_error(
        Sftp::Client::Error,
        'Could not list files on the sftp server: Net::SSH::ConnectionTimeout'
      )
    end
  end

  describe '#download' do
    let(:file) { Sftp::File.new('test.xml.tar.gz') }
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
        'Could not download file from sftp server: Net::SFTP::Exception'
      )
    end
  end

  describe '#download_all' do
    let(:sftp_dir) { instance_double(Net::SFTP::Operations::Dir) }
    let(:sftp_downloader) { instance_double(Net::SFTP::Operations::Download) }

    let(:files) do
      [
        instance_double(Net::SFTP::Protocol::V04::Name, name: 'test_file_1.xml.tar.gz'),
        instance_double(Net::SFTP::Protocol::V04::Name, name: 'test_file_2.xml.tar.gz')
      ]
    end

    before do
      allow(sftp_session).to receive(:dir).and_return(sftp_dir)
      allow(sftp_dir).to receive(:glob).and_return(files)
      allow(sftp_session).to receive(:download).and_return(sftp_downloader)
      allow(sftp_downloader).to receive(:wait).and_return(sftp_downloader)
    end

    it 'downloads all matching files from remote directory' do
      client.download_all(matching: 'test.xml.tar.gz')
      expect(sftp_session).to have_received(:download).twice
      expect(sftp_downloader).to have_received(:wait).twice
    end
  end

  describe '#delete' do
    let(:file) { Sftp::File.new('test.xml.tar.gz') }
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
        'Could not delete file on sftp server: Net::SFTP::Exception'
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
                                            'Could not connect to sftp server: Net::SSH::Exception')
    end
  end
end
