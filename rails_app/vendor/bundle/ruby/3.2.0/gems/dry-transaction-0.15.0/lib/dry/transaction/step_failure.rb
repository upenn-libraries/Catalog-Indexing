# frozen_string_literal: true

module Dry
  module Transaction
    # A wrapper for storing together the step that failed
    # and value describing the failure.
    class StepFailure
      attr_reader :step
      attr_reader :value

      # @api private
      def self.call(step, value)
        # rubocop:disable Style/CaseEquality
        if self === value
          value
        else
          yield
          new(step, value)
        end
        # rubocop:enable Style/CaseEquality
      end

      def initialize(step, value)
        @step = step
        @value = value
      end
    end
  end
end
