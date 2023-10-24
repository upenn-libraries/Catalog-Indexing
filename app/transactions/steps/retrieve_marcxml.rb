# frozen_string_literal: true

module Steps
  # Step to get MARCXML for n records from the Alma API based on an array of identifiers
  class RetrieveMARCXML
    include Dry::Monads[:result]

    # Get MARCXML from Alma API
    # @param [Array<String>] identifiers
    # @return [Dry::Monads::Result]
    def call(identifiers:, **args)
      docs = []
      identifiers.in_groups_of(AlmaApi::Client::MAX_BIBS_GET, false).each do |group|
        response = AlmaApi::Client.new.bibs group
        docs += response['bib']&.filter_map do |bib_data|
          bib_data['anies'].first
        end
      end
      Success(docs: docs, **args)
    rescue StandardError => e
      Failure(e)
    end
  end
end