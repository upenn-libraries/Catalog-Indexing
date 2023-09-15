# frozen_string_literal: true

namespace :tools do
  desc 'Initialize project, including Solr collections and database'
  task start: :environment do
    puts 'Starting Solr and Database services...'
    system('COMPOSE_PROJECT_NAME=catalog-indexing docker-compose up -d')
    puts 'Setting up basic auth for Solr...' # TODO: only run if needed...
    system('docker-compose exec solrcloud solr auth enable -credentials catalog:catalog')
    solr_admin = Solr::Admin.new
    unless solr_admin.collection_exists?(name: 'catalog-dev')
      puts 'Uploading configset from solr/conf'
      solr_admin.upload_config
      puts 'Creating catalog-dev and catalog-test collections'
      solr_admin.create_collection(name: 'catalog-development')
      solr_admin.create_collection(name: 'catalog-test')
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
    FactoryBot.create_list(:alma_export, 5)
    FactoryBot.create_list(:alma_export_with_files, 5)
  end
end
