# frozen_string_literal: true

require 'net/sftp'

module Sftp
  # API for interacting with SFTP server that stores Alma publish files
  class Client
    class Error < StandardError; end

    attr_reader :sftp

    delegate :close_channel, to: :sftp

    def initialize
      @sftp = Net::SFTP.start(sftp_host, sftp_username, password: sftp_password)
    rescue RuntimeError => e
      raise Error, "Could not connect to SFTP server: #{e.message}"
    end

    # List all files on the SFTP server and return Sftp::File objects
    # @return [Array<Sftp::File>] list of Sftp::File objects
    def files
      sftp.dir.entries(sftp_root).map do |entry|
        Sftp::File.new(entry.name)
      end
    rescue RuntimeError => e
      raise Error, "Could not list files on the SFTP server: #{e.message}"
    end

    # download single file from sftp server
    # @param [Sftp::File]
    # @param wait [Boolean] determines whether to run the event loop, allowing the download to progress
    # @return [Net::SFTP::Operations::Download]
    def download(file, wait: true)
      ::File.truncate(file.local_path, 0) if file.downloaded?
      begin
        download = sftp.download(file.remote_path, file.local_path)
        return download unless wait

        download.wait
      rescue RuntimeError => e
        raise Error, "Could not download file from SFTP server: #{e.message}"
      end
    end

    # delete file on sftp server
    # @param [Sftp::File]
    def delete(file)
      sftp.remove(file.remote_path).wait
    rescue RuntimeError => e
      raise Error, "Could not delete file on SFTP server: #{e.message}"
    end

    private

    # @return [String]
    def sftp_username
      Settings.sftp.username
    end

    # @return [String]
    def sftp_password
      Settings.sftp.password
    end

    # @return [String]
    def sftp_host
      Settings.sftp.host
    end

    # @return [String]
    def sftp_root
      Settings.sftp.root
    end
  end
end
