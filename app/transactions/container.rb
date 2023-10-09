# frozen_string_literal: true

# Transaction container
class Container
  extend Dry::Core::Container::Mixin

  namespace 'traject' do
    register 'index_records' do
      Steps::IndexRecords.new
    end
  end

  register 'prepare_marcxml' do
    Steps::PrepareMARCXML.new
  end
end
