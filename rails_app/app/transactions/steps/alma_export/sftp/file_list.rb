# frozen_string_literal: true

module Steps
  module AlmaExport
    module Sftp
      # Step get a listing of Sftp files
      class FileList
        include Dry::Monads[:result]
        include Support::ErrorHandling

        RECORD_TYPE = :record
        DELETE_TYPE = :delete
        LIST_TYPES = [RECORD_TYPE, DELETE_TYPE].freeze

        # @param type [Symbol]
        def initialize(type:)
          raise(ArgumentError, "Unsupported type for SFTP file list: #{type}") unless type.in?(LIST_TYPES)

          @type = type
        end

        # get Sftp::File objects via SFTP entries
        # @param alma_export [::AlmaExport]
        # @param sftp_session [Sftp::Client]
        # @return [Dry::Monads::Result]
        def call(alma_export:, sftp_session:, **args)
          files_matching = files_matching_regex(job_identifier: alma_export.job_identifier)
          file_list = sftp_session.files.select { |f| f.name =~ files_matching }

          Success(alma_export: alma_export, file_list: file_list, sftp_session: sftp_session, **args)
        rescue StandardError => e
          handle_failure alma_export, "Unexpected error (#{e.class.name}) during SFTP list: #{e.message}"
        end

        private

        # @param job_identifier [String]
        # @return [Regexp]
        def files_matching_regex(job_identifier:)
          case @type.to_sym
          when :delete then /_#{job_identifier}_.*_delete_?\d*.tar.gz/
          when :record then /_#{job_identifier}_.*_new_?\d*.tar.gz/
          end
        end
      end
    end
  end
end
