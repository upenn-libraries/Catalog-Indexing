# -*- encoding: utf-8 -*-
# stub: upennlib-rubocop 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "upennlib-rubocop".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Carla Galarza".freeze, "Mike Kanning".freeze]
  s.date = "2023-03-24"
  s.description = "UPenn Libraries Rubocop Configuration".freeze
  s.email = "cgalarza@upenn.edu".freeze
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Rubocop style configuration to be used in UPenn Libraries Projects".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rubocop>.freeze, ["~> 1.24"])
  s.add_runtime_dependency(%q<rubocop-capybara>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rubocop-performance>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rubocop-rails>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rubocop-rake>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<rubocop-rspec>.freeze, [">= 0"])
end
