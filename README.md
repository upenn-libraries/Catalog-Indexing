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
bundle exec sidekiw
```
