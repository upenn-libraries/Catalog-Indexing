# frozen_string_literal: true

class Container
  extend Dry::Core::Container::Mixin

  namespace 'traject' do
    register 'index_records' do
      Steps::IndexRecords.new
    end
  end
end