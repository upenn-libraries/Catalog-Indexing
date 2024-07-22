# frozen_string_literal: true

require 'dry/transaction'
require 'rubygems/package'

# Handle AlmaExport processing for an incremental publish. Downloads all files from SFTP and enqueues jobs to
# process BatchFiles and deletes.
# ID for example use: 59711274490003681
class ProcessIncrementalAlmaExport
  include Dry::Transaction(container: Container)
  include Steps::AlmaExport::Support::ErrorHandling

  SFTP_PARALLEL_DOWNLOADS = 20

  step :load_alma_export, with: 'alma_export.find'
  step :initialize_sftp_session, with: 'alma_export.sftp.session'
  step :get_record_files, with: 'alma_export.sftp.file_list_record'
  step :get_target_collections, with: 'config_item.value'
  step :validate_config_collections, with: 'config_item.validate'
  step :prepare_batch_job, with: 'alma_export.prepare_batch_job'
  step :update_alma_export, with: 'alma_export.update'
  step :accumulate_ids_for_deletion
  step :delete_from_solr
  step :process_sftp_files, with: 'alma_export.process_batch_files'
  step :populate_batch_job, with: 'alma_export.batch_job.populate'

  # Set desired ConfigItem value
  # @return [Dry::Monads::Result]
  def get_target_collections(**args)
    super(config_item_name: :incremental_target_collections, **args)
  end

  # Pass ConfigItem values to validate step
  # @param config_value [Array<String>]
  # @return [Dry::Monads::Result]
  def validate_config_collections(config_value:, **args)
    super(collections: config_value, **args)
  end

  # Download, read and extract MMS IDs for deleted records from _delete file(s)
  # @param [AlmaExport] alma_export
  # @param [Sftp::Client] sftp_session
  # @return [Dry::Monads::Result]
  def accumulate_ids_for_deletion(alma_export:, sftp_session:, **args)
    delete_files = sftp_session.files matching: files_matching_regex(alma_export.alma_job_identifier, deletes: true)
    return Success(alma_export: alma_export, ids: [], **args) if delete_files.empty?

    delete_files.each_with_object do |delete_file, ids|
      sftp_session.download(delete_file)
      ids << ids_from_file(delete_file)
    end
    Success(alma_export: alma_export, ids: ids.flatten.uniq, **args)
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
      unless solr.delete(id: ids).response[:status] == 200
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
