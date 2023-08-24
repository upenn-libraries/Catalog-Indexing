# Catalog Indexing App

Rails app to build and maintain Solr collections for the Penn Libraries catalog.

## Development

Staring services:

```rake tools:start```

Stopping services:

```rake tools:stop```

Cleaning up:

```rake tools:clean```

### Sidekiq

You can start sidekiq in development using:

```ruby
bundle exec sidekiq
```

This is not *required*, but is a good idea if you want to app to function as expected during development. Running the 
sidekiq process is not needed to run the test suite.

## PennMARC

This app uses the PennMARC gem to handle most of the MARC parsing logic.

### Developing

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
