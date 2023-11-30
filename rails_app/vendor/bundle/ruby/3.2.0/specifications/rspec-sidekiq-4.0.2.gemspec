# -*- encoding: utf-8 -*-
# stub: rspec-sidekiq 4.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-sidekiq".freeze
  s.version = "4.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aidan Coyle".freeze, "Phil Ostler".freeze, "Will Spurgin".freeze]
  s.date = "2023-08-25"
  s.description = "Simple testing of Sidekiq jobs via a collection of matchers and helpers".freeze
  s.homepage = "http://github.com/wspurgin/rspec-sidekiq".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "RSpec for Sidekiq".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rspec-core>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<rspec-mocks>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<rspec-expectations>.freeze, ["~> 3.0"])
  s.add_runtime_dependency(%q<sidekiq>.freeze, [">= 5", "< 8"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-doc>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry-nav>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<coveralls>.freeze, [">= 0"])
  s.add_development_dependency(%q<fuubar>.freeze, [">= 0"])
  s.add_development_dependency(%q<activejob>.freeze, [">= 0"])
  s.add_development_dependency(%q<actionmailer>.freeze, [">= 0"])
  s.add_development_dependency(%q<activerecord>.freeze, [">= 0"])
  s.add_development_dependency(%q<activemodel>.freeze, [">= 0"])
  s.add_development_dependency(%q<activesupport>.freeze, [">= 0"])
end
