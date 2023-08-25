# frozen_string_literal: true

module Sftp
  # Interface to work with Alma files published on sftp server
  class PublishFile
    attr_reader :name

    def initialize(name)
      @name = name
    end

    # @return [String] path on remote storage
    def remote_path
      @remote_path ||= File.join(Sftp::Client::ROOT, name)
    end

    # @param [String] dir local directory of alma publish files
    # @return [String] path on local storage
    def local_path(dir: 'storage')
      @local_path ||= Rails.root.join(dir, name).to_s
    end

    # @return [Boolean]
    def downloaded?
      File.exist?(local_path)
    end
  end
end
