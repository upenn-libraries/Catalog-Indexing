# frozen_string_literal: true

namespace :tools do
  desc 'Initialize project, including Solr collections and database'
  task start: :environment do
    puts 'Starting Solr and Database services...'
    system('COMPOSE_PROJECT_NAME=catalog-indexing docker-compose up -d')
    puts 'Setting up basic auth for Solr...' # TODO: only run if needed...
    system('docker-compose exec solrcloud solr auth enable -credentials admin:password')
    solr_admin = Solr::Admin.new
    unless solr_admin.collection_exists?(name: 'catalog-dev')
      puts 'Uploading configset from solr/conf'
      solr_admin.upload_config
      puts 'Creating catalog-indexing-dev and catalog-indexing-test collections'
      solr_admin.create_collection(name: 'catalog-indexing-dev')
      solr_admin.create_collection(name: 'catalog-indexing-test')
    end

    # Create databases, if they aren't present.
    begin
      ActiveRecord::Base.connection
    rescue ActiveRecord::NoDatabaseError
      ActiveRecord::Tasks::DatabaseTasks.create_current
    end

    # Migrate test and development databases
    system('RAILS_ENV=development rake db:migrate')
    system('RAILS_ENV=test rake db:migrate')
  end

  desc 'Stops running containers'
  task stop: :environment do
    system('COMPOSE_PROJECT_NAME=catalog-indexing docker-compose stop')
  end

  desc 'Removes containers and volumes'
  task clean: :environment do
    system('COMPOSE_PROJECT_NAME=catalog-indexing docker-compose down --volumes')
  end

  desc 'Generates some alma exports'
  task generate_sample_alma_exports: :environment do
    FactoryBot.create_list(:alma_export_with_files, 5)
  end

  # JOB_ID=55827228880003681 bundle exec rake tools:process_full_index
  desc 'Test full export processing'
  task process_full_index: :environment do
    SolrTools.delete_collection(SolrTools.new_collection_name) if SolrTools.collection_exists?(SolrTools.new_collection_name)
    Sidekiq.redis(&:flushdb)
    AlmaExport.destroy_all
    job_id = ENV.fetch('JOB_ID', nil)
    webhook_response_fixture = Rails.root.join('spec/fixtures/json/webhooks/job_end_success.json').read
    webhook_response_fixture.gsub!('50746714710003681', job_id) if job_id
    alma_export = AlmaExport.create!(status: Statuses::PENDING, alma_source: AlmaExport::Sources::PRODUCTION,
                                     webhook_body: JSON.parse(webhook_response_fixture))
    ProcessAlmaExport.new.call(alma_export_id: alma_export.id)
  end

  desc 'Create Solr JSON from Alma set'
  task generate_solr_json_from_set: :environment do
    set_id = ENV.fetch('SET_ID', '51703864050003681') # default to NewCatSampleRecordsforTesting set
    puts IndexBySetToFile.new.call(set_id: set_id)
  end

  desc 'Package Solr config set for sharing'
  task package_configset: :environment do
    datestamp = DateTime.current.strftime('%Y%m%d')
    File.write("storage/configset_#{datestamp}.zip", File.read(Solr::Config.new.tempfile))
  end

  desc 'Add Configuration Items to the database with default values'
  task add_config_items: :environment do
    ConfigItem.find_or_create_by name: 'process_job_webhooks', config_type: ConfigItem::BOOLEAN_TYPE,
                                 value: ConfigItem::DETAILS.dig(:process_job_webhooks, :default)
    ConfigItem.find_or_create_by name: 'process_bib_webhooks', config_type: ConfigItem::BOOLEAN_TYPE,
                                 value: ConfigItem::DETAILS.dig(:process_bib_webhooks, :default)
    ConfigItem.find_or_create_by name: 'webhook_target_collections', config_type: ConfigItem::ARRAY_TYPE,
                                 value: ConfigItem::DETAILS.dig(:webhook_target_collections, :default)
    ConfigItem.find_or_create_by name: 'adhoc_target_collections', config_type: ConfigItem::ARRAY_TYPE,
                                 value: ConfigItem::DETAILS.dig(:adhoc_target_collections, :default)
  end
end
