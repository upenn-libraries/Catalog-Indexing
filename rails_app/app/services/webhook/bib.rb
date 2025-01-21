# frozen_string_literal: true

module Webhook
  # Represent an Alma Bib webhook
  class Bib < Payload
    # @return [String]
    def id
      data['id']
    end

    # @return [String]
    def event
      data.dig 'event', 'value'
    end

    # @return [String]
    def marcxml
      data.dig 'bib', 'anies'
    end

    # @return [Boolean]
    def suppress_from_publishing?
      data.dig('bib', 'suppress_from_publishing') == 'true'
    end

    # @return [Boolean]
    def suppress_from_external_search?
      data.dig('bib', 'suppress_from_external_search') == 'true'
    end

    # @return [Boolean]
    def suppress_from_discovery?
      suppress_from_external_search? || suppress_from_publishing?
    end
  end
end
