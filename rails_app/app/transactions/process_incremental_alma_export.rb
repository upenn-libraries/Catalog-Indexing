# frozen_string_literal: true

require 'dry/transaction'
require 'rubygems/package'

# Handle AlmaExport processing for an incremental publish. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles and deletes.
# ID for example use: 59711274490003681
class ProcessIncrementalAlmaExport
  include Dry::Transaction(container: Container)
  include Steps::AlmaExport::Support::ErrorHandling

  step :load_alma_export, with: 'alma_export.find'
  step :initialize_sftp_session, with: 'alma_export.sftp.open'
  step :get_target_collections, with: 'config_item.incremental_target_collections'
  step :validate_config_collections, with: 'solr.validate_collections'
  step :prepare_batch_job, with: 'alma_export.batch_job.prepare'
  step :update_alma_export, with: 'alma_export.update'
  step :list_delete_files, with: 'alma_export.sftp.file_list_delete'
  step :accumulate_ids_for_deletion
  step :delete_from_solr
  step :list_record_files, with: 'alma_export.sftp.file_list_record'
  step :close_sftp_session, with: 'alma_export.sftp.close'
  step :process_sftp_files, with: 'alma_export.process_batch_files'
  step :populate_batch_job, with: 'alma_export.batch_job.populate'

  # Download, read and extract MMS IDs for deleted records from _delete file(s)
  # @param alma_export [AlmaExport]
  # @param sftp_session [Sftp::Client]
  # @param file_list [Array<::Sftp::File] delete files
  # @return [Dry::Monads::Result]
  def accumulate_ids_for_deletion(alma_export:, sftp_session:, file_list:, **args)
    return Success(alma_export: alma_export, sftp_session: sftp_session, ids: [], **args) if file_list.empty?

    ids = []
    file_list.each do |delete_file|
      sftp_session.download(delete_file)
      ids << ids_from_file(delete_file)
    end
    Success(alma_export: alma_export, sftp_session: sftp_session, ids: ids.flatten.uniq, **args)
  rescue StandardError => e
    handle_failure(alma_export, "Problem handling delete file: #{e.message}")
  end

  # Issue deletes to Solr for configured collections, using IDs provided
  # @param [AlmaExport] alma_export
  # @param [Array] ids
  # @return [Dry::Monads::Result]
  def delete_from_solr(alma_export:, ids:, **args)
    return Success(alma_export: alma_export, **args) if ids.empty?

    solr_clients = alma_export.target_collections.map { |collection| Solr::QueryClient.new(collection: collection) }
    solr_clients.each do |solr|
      unless solr.delete(ids: ids).response[:status] == 200
        raise StandardError, "Problem when deleting records from Solr collection #{solr.collection}"
      end
    end
    Success(alma_export: alma_export, **args)
  rescue StandardError => e
    handle_failure alma_export, e.message
  end

  private

  # Decompress, extract and parse MMS IDs from MARCXML given a downloaded Sftp::File
  # @param delete_file [Sftp::File]
  # @return [Array<String>]
  def ids_from_file(delete_file)
    io = Gem::Package::TarReader.new(Zlib::GzipReader.new(File.open(delete_file.local_path))).first
    records = MARC::XMLReader.new(io, parser: :nokogiri, ignore_namespace: true)
    records.map { |r| r['001'].value }
  end
end
