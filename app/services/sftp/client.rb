# frozen_string_literal: true

require 'net/sftp'

module Sftp
  # API for interacting with SFTP server that stores Alma publish files
  class Client
    HOST = 'move.library.upenn.edu'
    ROOT = '/recordstoalma/bibexport'
    class Error < StandardError; end

    attr_accessor :sftp

    def initialize
      @sftp = Net::SFTP.start(HOST, sftp_username, password: sftp_password)
    rescue RuntimeError => e
      raise Error, "Could not connect to sftp server: #{e.message}"
    end

    # list files on sftp server that match pattern, returning Sftp::File objects
    # @param [String] matching prefix to match files in directory
    # @return [Array<Sftp::File>] list of Sftp::File objects
    def files(matching:)
      sftp.dir.entries(ROOT).filter_map do |entry|
        Sftp::File.new(entry.name) if desired_file?(entry.name, matching)
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

    # delete file on sftp server
    # @param [Sftp::File]
    def delete(file)
      sftp.remove(file.remote_path).wait
    rescue RuntimeError => e
      raise Error, "Could not delete file on sftp server: #{e.message}"
    end

    private

    # Determine if a file in the SFTP directory is desired in this operation
    # @param [String] file_name
    # @return [Boolean]
    def desired_file?(file_name, matching)
      file_name.match?(matching) && file_name.ends_with?('.xml.tar.gz')
    end

    # @return String
    def sftp_username
      @sftp_username ||= Rails.application.credentials.sftp_username
    end

    # @return String
    def sftp_password
      @sftp_password ||= Rails.application.credentials.sftp_password
    end
  end

  # API for interacting with SFTP server that stores Alma publish files
  class ExpClient
    HOST = 'move.library.upenn.edu'
    ROOT = '/recordstoalma/bibexport'

    class Error < StandardError; end

    def self.files(matching:)
      files = []
      Net::SFTP.start(HOST, sftp_username, password: sftp_password) do |sftp|
        sftp.dir.entries(ROOT).each do |file|
          files << Sftp::File.new(file.name) if desired_file?(file, matching)
        end
      end
      files
    end

    def self.download(sftp_files)
      Net::SFTP.start(HOST, sftp_username, password: sftp_password) do |sftp|

      end

      files.each_slice(CONCURRENT_DOWNLOADS) do |slice|
        sftp_downloads(slice, sftp, completed_proc).each(&:wait)
      end
    end

    # @param [Regexp] matching to match interesting files, use date or Job ID
    # @return [Array<Sftp::File>]
    def downloads(matching:, completed_proc:)
      files = []
      Net::SFTP.start(HOST, sftp_username, password: sftp_password) do |sftp|
        sftp.dir.entries(ROOT).each do |file|
          files << Sftp::File.new(file.name) if desired_file?(file, matching)
        end
        files.each_slice(CONCURRENT_DOWNLOADS) do |slice|
          sftp_downloads(slice, sftp, completed_proc).each(&:wait)
        end
      end
      files
    end

    private

    # @param [Array<Sftp::File>] files
    # @param [Net::SFTP::Session] sftp
    # @return [Array<Net::SFTP::Operations::Download>]
    def sftp_downloads(files, sftp, completed_proc)
      files.map do |file|
        ::File.truncate(file.local_path, 0) if ::File.exist?(file.local_path)
        sftp.download(file.remote_path, file.local_path) do |event, _downloader, *_args|
          case event
          when :close
            puts "File downloaded: #{file.remote_path}"
            completed_proc.call(file)
          end
        end
      end
    end

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
