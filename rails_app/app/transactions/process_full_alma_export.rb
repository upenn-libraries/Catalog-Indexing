# frozen_string_literal: true

require 'dry/transaction'

# Handle AlmaExport processing for a full publish. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles
class ProcessFullAlmaExport
  include Dry::Transaction(container: Container)

  step :load_alma_export, with: 'alma_export.find'
  step :initialize_sftp_session, with: 'alma_export.sftp.open'
  step :get_sftp_files_list, with: 'alma_export.sftp.file_list_record'
  step :close_sftp_session, with: 'alma_export.sftp.close'
  step :ensure_files_present
  step :prepare_batch_job, with: 'alma_export.batch_job.prepare'
  step :prepare_solr_collection, with: 'solr.create_collection'
  step :update_alma_export, with: 'alma_export.update'
  step :process_sftp_files, with: 'alma_export.process_batch_files'
  step :populate_batch_job, with: 'alma_export.batch_job.populate'

  # Ensure that we have some files to work with. In a full export context, it's an error case if we don't have any
  # files.
  # @param [Array] file_list
  # @return [Dry::Monads::Result]
  def ensure_files_present(file_list:, **args)
    return Failure(message: 'No SFTP files found!') if file_list.empty?

    Success(file_list: file_list, **args)
  end
end
