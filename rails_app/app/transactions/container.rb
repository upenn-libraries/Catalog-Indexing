# frozen_string_literal: true

# Transaction container
class Container
  extend Dry::Core::Container::Mixin

  namespace 'alma_export' do
    register('find') { Steps::AlmaExport::Find.new }
    register('update') { Steps::AlmaExport::Update.new }
    register('process_batch_files') { Steps::AlmaExport::ProcessBatchFiles.new }

    namespace 'batch_job' do
      register('prepare') { Steps::AlmaExport::BatchJob::Prepare.new }
      register('populate') { Steps::AlmaExport::BatchJob::Populate.new }
    end

    namespace 'sftp' do
      register('open') { Steps::AlmaExport::Sftp::OpenSession.new }
      register('close') { Steps::AlmaExport::Sftp::CloseSession.new }
      register('file_list_record') { Steps::AlmaExport::Sftp::FileList.new(type: :record) }
      register('file_list_delete') { Steps::AlmaExport::Sftp::FileList.new(type: :delete) }
    end
  end

  namespace 'solr' do
    register('create_collection') { Steps::Solr::CreateCollection.new }
    register('validate_collections') { Steps::Solr::ValidateCollections.new }
  end

  namespace 'config_item' do
    register('value') { Steps::ConfigItemValue.new }
    register('incremental_target_collections') do
      Steps::ConfigItemValue.new(name: :incremental_target_collections, as: :collections)
    end
  end

  namespace 'traject' do
    register('index_records') { Steps::IndexRecords.new }
  end

  namespace 'marcxml' do
    register('retrieve') { Steps::RetrieveMARCXML.new }
    register('prepare') { Steps::PrepareMARCXML.new }
  end

  namespace 'webhooks' do
    register('get_collections') { Steps::GetCollections.new }
  end
end
