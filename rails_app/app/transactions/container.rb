# frozen_string_literal: true

# Transaction container
class Container
  extend Dry::Core::Container::Mixin

  namespace 'alma_export' do
    register 'find' do
      Steps::AlmaExport::Find.new
    end

    register 'update' do
      Steps::AlmaExport::Update.new
    end

    namespace 'batch_job' do
      register 'prepare_batch_job' do
        Steps::AlmaExport::Prepare.new
      end

      register 'populate_batch_job' do
        Steps::AlmaExport::Populate.new
      end
    end

    namespace 'sftp' do
      register 'session' do
        Steps::Sftp::Session.new
      end

      register 'file_list_record' do
        Steps::Sftp::FileList.new(type: :record)
      end

      register 'file_list_delete' do
        Steps::Sftp::FileList.new(type: :delete)
      end
    end
  end

  namespace 'solr' do
    register 'create_collection' do
      Steps::Solr::CreateCollection.new
    end

    register 'validate_collection' do
      Steps::Solr::ValidateCollections.new
    end
  end

  namespace 'config_item' do
    register 'value' do
      Steps::ConfigItemValue.new
    end
  end

  namespace 'traject' do
    register 'index_records' do
      Steps::IndexRecords.new
    end
  end

  namespace 'marcxml' do
    register 'retrieve' do
      Steps::RetrieveMARCXML.new
    end

    register 'prepare' do
      Steps::PrepareMARCXML.new
    end
  end

  namespace 'webhooks' do
    register 'get_collections' do
      Steps::GetCollections.new
    end
  end
end
