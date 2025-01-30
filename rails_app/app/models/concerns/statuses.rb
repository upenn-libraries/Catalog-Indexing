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

  module Style
    PENDING = 'text-bg-info'
    IN_PROGRESS = 'text-bg-primary'
    COMPLETED = 'text-bg-success'
    COMPLETED_WITH_ERRORS = 'text-bg-warning'
    FAILED = 'text-bg-danger'
  end

  included do
    validates :status, inclusion: Statuses::ALL, presence: true
  end

  # Class for status badge
  # @return [String]
  def badge_class
    { PENDING => Style::PENDING,
      IN_PROGRESS => Style::IN_PROGRESS,
      COMPLETED => Style::COMPLETED,
      COMPLETED_WITH_ERRORS => Style::COMPLETED_WITH_ERRORS,
      FAILED => Style::FAILED }[status]
  end
end
