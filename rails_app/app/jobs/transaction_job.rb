# frozen_string_literal: true

# Class that jobs can inherit from when using transactions in jobs. This class overrides the #perform method
# so that Failure monads are raised as exceptions and therefore be retried via Sidekiq.
class TransactionJob
  include Sidekiq::Job

  def transaction(*_args)
    raise '#transaction must be implemented when inheriting from TransactionJob'
  end

  def perform(*args)
    result = transaction(*args)

    return if result.success?

    failure = result.failure

    raise failure[:exception] if failure[:exception]

    raise StandardError, failure[:error].to_s.titleize
  end
end
