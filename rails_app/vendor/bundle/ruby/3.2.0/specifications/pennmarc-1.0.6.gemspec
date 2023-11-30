# -*- encoding: utf-8 -*-
# stub: pennmarc 1.0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "pennmarc".freeze
  s.version = "1.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Kanning".freeze, "Amrey Mathurin".freeze, "Patrick Perkins".freeze]
  s.date = "2023-11-09"
  s.description = "This gem provides methods for parsing a Penn Libraries MARCXML record into string, array and date\n                   objects for use in discovery or preservation applications.".freeze
  s.email = "mkanning@upenn.edu".freeze
  s.homepage = "https://gitlab.library.upenn.edu/dld/catalog/pennmarc".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.2".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Penn Libraries Catalog MARC parsing wisdom for cross-project usage".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<activesupport>.freeze, ["~> 7"])
  s.add_runtime_dependency(%q<library_stdnums>.freeze, ["~> 1.6"])
  s.add_runtime_dependency(%q<marc>.freeze, ["~> 1.2"])
  s.add_runtime_dependency(%q<nokogiri>.freeze, ["~> 1.15"])
end
