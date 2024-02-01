# Catalog Indexing Rails App

Rails app to build and maintain Solr collections for the Penn Libraries catalog.

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
rake tools:package configset
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