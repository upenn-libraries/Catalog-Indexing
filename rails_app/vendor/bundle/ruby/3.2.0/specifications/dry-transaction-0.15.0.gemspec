# -*- encoding: utf-8 -*-
# stub: dry-transaction 0.15.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-transaction".freeze
  s.version = "0.15.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-transaction/issues", "changelog_uri" => "https://github.com/dry-rb/dry-transaction/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-transaction" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tim Riley".freeze]
  s.date = "2022-11-16"
  s.description = "Business Transaction Flow DSL".freeze
  s.email = ["tim@icelab.com.au".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-transaction".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Business Transaction Flow DSL".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<dry-events>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<dry-matcher>.freeze, ["~> 0.10"])
  s.add_runtime_dependency(%q<dry-monads>.freeze, ["~> 1.6"])
end
