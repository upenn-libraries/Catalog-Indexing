# -*- encoding: utf-8 -*-
# stub: dry-matcher 0.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-matcher".freeze
  s.version = "0.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/dry-rb/dry-matcher/issues", "changelog_uri" => "https://github.com/dry-rb/dry-matcher/blob/main/CHANGELOG.md", "source_code_uri" => "https://github.com/dry-rb/dry-matcher" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Tim Riley".freeze, "Nikita Shilnikov".freeze]
  s.date = "2022-11-16"
  s.description = "Flexible, expressive pattern matching for Ruby".freeze
  s.email = ["tim@icelab.com.au".freeze, "fg@flashgordon.ru".freeze]
  s.homepage = "https://dry-rb.org/gems/dry-matcher".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Flexible, expressive pattern matching for Ruby".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<dry-core>.freeze, ["~> 1.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
