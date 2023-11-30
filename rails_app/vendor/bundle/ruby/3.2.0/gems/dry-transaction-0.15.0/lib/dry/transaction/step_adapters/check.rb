# frozen_string_literal: true

module Dry
  module Transaction
    class StepAdapters
      # @api private
      class Check
        include Dry::Monads[:result]

        def call(operation, _options, args)
          input = args[0]
          res = operation.(*args)
          res == true || res.is_a?(Success) ? Success(input) : Failure(input)
        end
      end

      register :check, Check.new
    end
  end
end
