# frozen_string_literal: true

module Steps
  module AlmaExport
    module Sftp
      # Step get a listing of Sftp files
      class FileList
        include Dry::Monads[:result]
        include Support::ErrorHandling

        LIST_TYPES = %w[record delete].freeze

        # @param type [Symbol]
        def initialize(type:)
          raise ArgumentError("Unsupported type for SFTP file list: #{type}") unless type.in?(LIST_TYPES)

          @type = type
        end

        # get Sftp::File objects via SFTP entries
        # @param alma_export [AlmaExport]
        # @param sftp_session [Sftp::Client]
        # @return [Dry::Monads::Result]
        def call(alma_export:, sftp_session:, **args)
          job_id = alma_export.alma_job_identifier
          file_list = sftp_session.files matching: files_matching_regex(job_id: job_id)
          if file_list.empty?
            return handle_failure(alma_export,
                                  "No #{@type} file(s) available for download for job ID: #{job_id}")
          end

          Success(alma_export: alma_export, file_list: file_list, **args)
        rescue StandardError => e
          handle_error alma_export, "Unexpected error (#{e.class.name}) during SFTP list: #{e.message}"
        end

        private

        # @param job_id [String]
        def files_matching_regex(job_id:)
          case @type
          when :delete then /_#{job_id}_.*_delete.tar.gz/
          when :record then /_#{job_id}_.*_new_\d+.tar.gz/
          end
        end
      end
    end
  end
end
