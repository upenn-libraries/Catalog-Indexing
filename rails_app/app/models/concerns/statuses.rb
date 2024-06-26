# frozen_string_literal: true

# Common statuses and associated behavior
module Statuses
  extend ActiveSupport::Concern

  PENDING = 'pending'
  IN_PROGRESS = 'in_progress'
  COMPLETED = 'completed'
  COMPLETED_WITH_ERRORS = 'completed with errors'
  FAILED = 'failed'
  ALL = [PENDING, IN_PROGRESS, COMPLETED, COMPLETED_WITH_ERRORS, FAILED].freeze
  INCOMPLETE_STATUSES = [PENDING, IN_PROGRESS].freeze
  PROBLEM_STATUSES = [COMPLETED_WITH_ERRORS, FAILED].freeze

  included do
    validates :status, inclusion: Statuses::ALL, presence: true
  end
end
