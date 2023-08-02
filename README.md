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

This is not *required*, but is a good idea if you want to app to function as expected during development. Running the sidekiq process is not needed to run the test suite.
