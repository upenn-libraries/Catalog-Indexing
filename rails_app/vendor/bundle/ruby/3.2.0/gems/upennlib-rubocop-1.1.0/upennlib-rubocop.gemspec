Gem::Specification.new do |s|
  s.name        = 'upennlib-rubocop'
  s.version     = '1.1.0'
  s.summary     = "Rubocop style configuration to be used in UPenn Libraries Projects"
  s.description = "UPenn Libraries Rubocop Configuration"
  s.authors     = ["Carla Galarza", "Mike Kanning"]
  s.email       = 'cgalarza@upenn.edu'
  s.files       = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)

  s.add_dependency 'rubocop', '~> 1.24'
  s.add_dependency 'rubocop-capybara'
  s.add_dependency 'rubocop-performance'
  s.add_dependency 'rubocop-rails'
  s.add_dependency 'rubocop-rake'
  s.add_dependency 'rubocop-rspec'
end
