# frozen_string_literal: true

module Webhook
  # Represent common properties of an Alma webhook response
  class Payload
    attr_accessor :data

    BIB_ACTION = 'BIB'
    JOB_END_ACTION = 'JOB_END'

    # Shortcut to build the proper object from parsed webhook payload
    # @param [Hash] payload
    # @return [Webhook::Payload, nil]
    def self.build(payload:)
      case payload['action']
      when BIB_ACTION
        Bib.new data: payload
      when JOB_END_ACTION
        Job.new data: payload
      end
    end

    # @param [Hash] data
    def initialize(data:)
      @data = data
    end

    def action
      data['action']
    end

    # @return [String]
    def event
      data.dig 'event', 'value'
    end
  end
end
