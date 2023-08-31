# frozen_string_literal: true

require 'net/sftp'

module Sftp
  # API for interacting with SFTP server that stores Alma publish files
  class Client
    HOST = 'move.library.upenn.edu'
    ROOT = '/recordstoalma/bibexport'
    class Error < StandardError; end

    # list files on sftp server that match pattern
    # @param [String] matching prefix to match files in directory
    # @return [Array<Sftp::File>] list of Sftp::File objects
    def files(matching:)
      @files ||= sftp.dir.glob(ROOT, matching).map do |entry|
        Sftp::File.new(entry.name)
      end
    rescue RuntimeError => e
      raise Error, "Could not list files on the sftp server: #{e.message}"
    end

    # download single file from sftp server
    # @param [Sftp::File]
    # @param [TrueClass | FalseClass] wait determines whether to run the event loop, allowing the download to progress
    # @return [Net::SFTP::Operations::Download]
    def download(file, wait: true)
      ::File.truncate(file.local_path, 0) if file.downloaded?
      begin
        download = sftp.download(file.remote_path, file.local_path)
        return download unless wait

        download.wait
      rescue RuntimeError => e
        raise Error, "Could not download file from sftp server: #{e.message}"
      end
    end

    # @todo i altered this to return the Sftp::File, did i slow the method down?
    # download all matching files on sftp server in parallel
    # @param [String] matching prefix to match files in directory
    # @return [Array <Sftp::File>]
    def download_all(matching:)
      files(matching: matching).map do |file|
        download(file, wait: true)
        file
      end
    end

    # delete file on sftp server
    # @param [Sftp::File]
    def delete(file)
      sftp.remove(file.remote_path).wait
    rescue RuntimeError => e
      raise Error, "Could not delete file on sftp server: #{e.message}"
    end

    # connect to sftp server
    def sftp
      @sftp ||= Net::SFTP.start(HOST, sftp_username, password: sftp_password)
    rescue RuntimeError => e
      raise Error, "Could not connect to sftp server: #{e.message}"
    end

    private

    # @return String
    def sftp_username
      @sftp_username ||= Rails.application.credentials.sftp_username
    end

    # @return String
    def sftp_password
      @sftp_password ||= Rails.application.credentials.sftp_password
    end
  end
end
