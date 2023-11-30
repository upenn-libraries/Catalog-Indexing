# UPenn Libraries RuboCop
[RuboCop](https://rubocop.org/) defaults for UPenn Libraries projects. Enforces a consistent Ruby style on our applications and gems.

## Purpose
This gem will centralize our RuboCop configuration and ensure we are using the same version of RuboCop across various projects. Projects that use this gem should avoid adding their own custom, project-specific RuboCop configuration. Instead developers should make an MR to this project with the suggested changes and an explanation as to why its necessary. The goal of this gem is to avoid having projects with different RuboCop rules because it makes it hard for developers to focus on writing code if the style changes from project to project.


## Installation & Usage

Add this line to your Gemfile:

```ruby
gem 'upennlib-rubocop', require: false
```

And then execute:

```
$ bundle install
```

In your `.rubocop.yml`:

```yml
inherit_gem:
  upennlib-rubocop: upennlib_rubocop_defaults.yml
```

## .rubocop_todo.yml
Understandably, it can be difficult to address all RuboCop issues when adding rubocop to a current project. If you want to delay fixing these issues, creating a `.rubocop_todo.yml` creates a list of exclusions for your RuboCop configuration. Using the following command creates a rubocop_todo configuration that only excludes files from cops instead of enabling/disabling cops and changing configuration values.

```
rubocop --auto-gen-config  --auto-gen-only-exclude --exclude-limit 10000
```

## Publishing Gem
To publish a new version of this gem to RubyGems:
1. Update the version number in `upennlib-rubocop.gemspec`
2. Create a Gitlab Release
3. Locally on your machine (with the lastest changes):
  ```
    gem build upennlib-rubocop.gemspec
    gem push upennlib-rubocop-{VERSION}.gem
  ```


