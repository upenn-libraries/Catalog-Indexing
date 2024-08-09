# frozen_string_literal: true

module Steps
  module AlmaExport
    # Shared step for downloading from a list of Sftp files and creating a BatchFile for each
    class ProcessBatchFiles
      include Dry::Monads[:result]
      include Support::ErrorHandling

      # In batches, download files, build BatchFile objects
      # @param alma_export [::AlmaExport]
      # @param file_list [Array<Sftp::File>]
      # @return [Dry::Monads::Result]
      def call(alma_export:, file_list:, **args)
        batch_files = []
        file_list.each_slice(Settings.sftp.parallel_downloads) do |slice|
          download_files(slice)
          batch_files << build_batch_files(alma_export, slice)
        end
        notify_slack(id: alma_export.id, count: file_list.count)
        Success(alma_export: alma_export, batch_files: batch_files.flatten, batch_job: args[:batch_job], **args)
      rescue StandardError => e
        message = "Error #{e.class.name} processing SFTP file: #{e.message}."
        handle_failure(alma_export, message)
      end

      private

      # @param files_slice [Array<Sftp::File]
      def download_files(files_slice)
        sftp_session = ::Sftp::Client.new # initialize a new connection for each batch to avoid connection being closed
        downloads = files_slice.map { |file| sftp_session.download(file, wait: false) }
        downloads.each(&:wait) # SFTP downloads occur concurrently here
        sftp_session.close_channel # close connection since we open a new once each iteration
      end

      # @param id [Integer]
      # @param count [Integer]
      def notify_slack(id:, count:)
        SendSlackNotificationJob.perform_async(
          "AlmaExport ##{id}: All #{count} files downloaded."
        )
      end

      # @param [::AlmaExport] alma_export
      # @param [Array<::Sftp::File>] sftp_files
      # @return [Array<BatchFile>]
      def build_batch_files(alma_export, sftp_files)
        sftp_files.map do |sftp_file|
          BatchFile.create!(alma_export_id: alma_export.id, path: sftp_file.local_path,
                            status: Statuses::PENDING)
        end
      end
    end
  end
end
