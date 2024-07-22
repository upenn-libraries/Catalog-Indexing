# frozen_string_literal: true

require 'dry/transaction'

# Handle AlmaExport processing for a full publish. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles
class ProcessFullAlmaExport
  include Dry::Transaction(container: Container)

  step :load_alma_export, with: 'alma_export.find'
  step :initialize_sftp_session, with: 'alma_export.sftp.session'
  step :get_sftp_files_list, with: 'alma_export.sftp.file_list_record'
  step :prepare_batch_job, with: 'alma_export.batch_job.prepare'
  step :prepare_solr_collection, with: 'solr.create_collection'
  step :update_alma_export, with: 'alma_export.update'
  step :process_sftp_files, with: 'alma_export.process_batch_files'
  step :populate_batch_job, with: 'alma_export.batch_job.populate'
end
