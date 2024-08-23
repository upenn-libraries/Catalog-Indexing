# Catalog Indexing Rails App

Rails app to build and maintain Solr collections for the Penn Libraries catalog. The application serves as the means for
processing MARC and writing to the Solr infrastructure used by the [Find catalog frontend](https://gitlab.library.upenn.edu/dld/catalog/find).

## Functionality

Data is processed via three means:
1. Alma Export processing - Bulk files of MARC are published by Alma via Publishing Profiles and moved onto a local SFTP location. A an Alma webhook is handled by this application that will trigger the initialization of a `ProcessAlmaExport` job that will download and prepare a `ProcessBatchFileJob` for each downloaded file. This process builds a brand new Solr collection each run.
2. Bib Webhooks - Alma webhooks are handled for changes to Bib records. For each received and supported Bib event, a `IndexByBibEvent` job is initialized that creates or updates the record in the configured index. This does not run the Bibs through the Alma publishing enrichment process.
3. Index by Identifier - A web form can receive a list of MMS IDs that will be retrieved from the Alma API and pushed to the configured index. This also does not run the Bibs through the Alma publishing enrichment process.

## Settings

The behavior of the application can be modified using the `Settings` area in the UI. The currently available parameters are:

* `Adhoc Target Collection` - The selected Solr collections will receive updates via the "Index by Identifier" process
* `Process Bib Webhooks` - When this is "On", this app will handle Alma `BIB` webhooks.
* `Process Job Webhook` - When this is "On", this app will handle Alma `JOB` webhooks for jobs that match the `Settings.alma.publishing_job.name` value.
* `Webhook Target Collections` - The selected Solr collections will receive updates via the `BIB` webhook jobs.
* `Incremental Target Collections` - The selected Solr collections will receive incremental updates via `JOB` webhooks for jobs matching the the `Settings.alma.publishing_job.name` value indicating the presence of updated or deleted records.

To make these settings accessible from the interface, you must run the following rake task [inside the application container](#interacting-with-the-application):
```bash
rake tools:add_config_items
```

## Local Development Environment

Our local development environment uses vagrant in order to set up a consistent environment with the required services. Please see the root README for instructions on how to set up this environment.
- The Rails application will be available at https://catalog-indexing-dev.library.upenn.edu.
- The Sidekiq Web UI will be available at http://catalog-indexing-dev.library.upenn.edu/sidekiq.
- The Solr admin console for the first instance will be available at http://catalog-indexing-dev.library.upenn.int/solr1/#/. Log-in with admin/password.

## Interacting with the Application
Once your local development environment is set up you can ssh into the vagrant box to interact with the application:

Enter the running Vagrant VM by running `vagrant ssh` in the `/vagrant` directory
Start a shell in the catalog-indexing container:

```bash
docker exec -it catalog-indexing_catalog_indexing.1.{whatever} bash
```

## Working with `find`

When [developing with find](https://gitlab.library.upenn.edu/dld/catalog/find#loading-data), you may need to generate a configset or some sample solr data from this app. Run these commands from the application container:

### Packaging the Solr configset

```bash
rake tools:package_configset
```

### Generating SolrJSON of the Alma sample set

```bash
rake tools:generate_solr_json_from_set
```

Using this JSONL file you can index records into your development instance of `find`.

## Running Test Suite

In order to run the test suite (currently):

1. Start a shell in the app container, see [interacting-with-the-application](#interacting-with-the-application)
2. Run `rspec` command: `RAILS_ENV=test bundle exec rspec`

## PennMARC

This app uses the PennMARC gem to handle most of the MARC parsing logic.

### Working with unpublished PennMARC versions

Sometimes you might want to use an unpublished version of the PennMARC gem in development. Modify the gemfile like so:

#### With a branch pushed to the remote (Gitlab)
```ruby
# Gemfile

gem 'pennmarc', git: 'https://gitlab.library.upenn.edu/dld/catalog/pennmarc.git', ref: 'some-remote-commit-sha'

# or

gem 'pennmarc', git: 'https://gitlab.library.upenn.edu/dld/catalog/pennmarc.git', branch: 'some-remote-branch'
```

#### With a local branch

You can instruct bundler to look at a local path for the `pennmarc` gem. When using this, running `bundle install` will
update your `Gemfile.lock` file to point to the specified `ref:` or `branch:` in your local `pennmarc` repo. Be very
careful to undo this when pushing to a remote branch.

```bash
bundle config set local.pennmarc ~/Projects/pennmarc/
```

```ruby
# Gemfile

gem 'pennmarc', git: 'https://gitlab.library.upenn.edu/dld/catalog/pennmarc.git', branch: 'some-local-branch-name'
```

Running `bundle install` should then show:

```bash
Using pennmarc 1.0.0 from https://gitlab.library.upenn.edu/dld/catalog/pennmarc.git (at /home/mk/Projects/pennmarc@ee38309)
```

## Code Linting and Formatting
### Rubocop
Rubocop is used to enforce style and formatting rules in our Ruby code. This application uses a custom set of rules contained within the [upennlib-rubocop](https://gitlab.library.upenn.edu/dld/upennlib-rubocop) gem.

#### To check style and formatting run:
```ruby
bundle exec rubocop
```

#### To regenerate `.rubocop_todo.yml`:
```shell
bundle exec rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```
