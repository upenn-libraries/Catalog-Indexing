# Catalog Indexing Rails App

Rails app to build and maintain Solr collections for the Penn Libraries catalog. The application processes MARC records and writes to the Solr infrastructure used by the [Find catalog frontend](https://gitlab.library.upenn.edu/dld/catalog/find).

---

## Table of Contents

1. [Functionality](#functionality)
2. [Settings](#settings)
3. [Local Development Environment](#local-development-environment)
4. [Interacting with the Application](#interacting-with-the-application)
5. [Working with Find](#working-with-find)
6. [Running the Test Suite](#running-the-test-suite)
7. [PennMARC](#pennmarc)
8. [Code Linting and Formatting](#code-linting-and-formatting)
9. [Contributing](#contributing)

---

## Functionality

The application processes MARC data using three main methods:

### 1. Alma Export Processing
- **Overview**: Bulk files of MARC are published by Alma via Publishing Profiles and moved to a local SFTP location.
- **Workflow**:
    - An Alma webhook triggers the `ProcessAlmaExport` job.
    - Files are downloaded and prepared for the `ProcessBatchFileJob`.
    - A new Solr collection is built for each run.

### 2. Bib Webhooks
- **Overview**: Processes Alma webhooks for changes to Bib records.
- **Workflow**:
    - For supported Bib events, an `IndexByBibEvent` job creates or updates records in the index.
    - These records are not processed through Alma’s publishing enrichment.

### 3. Index by Identifier
- **Overview**: A web form accepts MMS IDs to be fetched from the Alma API and pushed to the index.
- **Workflow**:
    - Records are directly indexed without Alma’s publishing enrichment.

---

## Settings

Modify the application's behavior using the **Settings** area in the UI. Available parameters:

- **Adhoc Target Collection**: Specifies Solr collections to receive updates via "Index by Identifier."
- **Process Bib Webhooks**: Enables processing of Alma `BIB` webhooks.
- **Process Job Webhook**: Enables processing of Alma `JOB` webhooks matching `Settings.alma.publishing_job.name`.
- **Webhook Target Collections**: Specifies Solr collections for updates via `BIB` webhook jobs.
- **Incremental Target Collections**: Specifies Solr collections for incremental updates via `JOB` webhooks for matched records.

To make these settings accessible, run:
```bash
rake tools:add_config_items
```

---

## Local Development Environment

Use Vagrant to set up a consistent local environment with required services.

### Prerequisites
- Install Vagrant and VirtualBox.

### Setup
1. Follow instructions in the root README for environment setup.
2. Access the Rails application at [https://catalog-indexing-dev.library.upenn.edu](https://catalog-indexing-dev.library.upenn.edu).
3. Access Sidekiq Web UI at [http://catalog-indexing-dev.library.upenn.edu/sidekiq](http://catalog-indexing-dev.library.upenn.edu/sidekiq).
4. Access Solr admin console at [http://catalog-indexing-dev.library.upenn.int/solr1/#/](http://catalog-indexing-dev.library.upenn.int/solr1/#/). Log in with `admin/password`.

---

## Interacting with the Application

### Accessing the Application Container
1. SSH into the Vagrant VM:
   ```bash
   vagrant ssh
   ```
2. Start a shell in the application container:
   ```bash
   docker exec -it catalog-indexing_catalog_indexing.1.{container_id} bash
   ```
   *(Find the container ID using `docker ps`.)*

---

## Working with Find

### Packaging the Solr Configset
Generate a Solr configset:
```bash
rake tools:package_configset
```

### Generating SolrJSON from Alma Sample Set
Generate SolrJSON:
```bash
rake tools:generate_solr_json_from_set
```
Use the resulting JSONL file to index records into your development instance of `find`.

---

## Running the Test Suite

### Steps
1. Start a shell in the app container (see [Interacting with the Application](#interacting-with-the-application)).
2. Run the test suite:
   ```bash
   RAILS_ENV=test bundle exec rspec
   ```

---

## PennMARC

This application uses the PennMARC gem to handle MARC parsing logic.

### Using Unpublished Versions
To use an unpublished version of PennMARC in development:

#### Using a Remote Branch
```ruby
# Gemfile
gem 'pennmarc', git: 'https://gitlab.library.upenn.edu/dld/catalog/pennmarc.git', branch: 'branch-name'
```

#### Using a Local Branch
Configure Bundler to use a local path:
```bash
bundle config set local.pennmarc ~/Projects/pennmarc/
```

Update the Gemfile:
```ruby
# Gemfile
gem 'pennmarc', git: 'https://gitlab.library.upenn.edu/dld/catalog/pennmarc.git', branch: 'local-branch-name'
```

Run `bundle install`. Ensure changes are reverted before pushing to remote.

---

## Code Linting and Formatting

### Rubocop
This application uses the [upennlib-rubocop](https://gitlab.library.upenn.edu/dld/upennlib-rubocop) gem for style enforcement.

#### Checking Style
```bash
bundle exec rubocop
```

#### Regenerating `.rubocop_todo.yml`
```bash
bundle exec rubocop --auto-gen-config --auto-gen-only-exclude --exclude-limit 10000
```

---

## Contributing

We welcome contributions! Please:
- Open issues or merge requests on the GitLab repository.
- Follow the style guidelines enforced by Rubocop.
- Write tests for any new functionality.

---

