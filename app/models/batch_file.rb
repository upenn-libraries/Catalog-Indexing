# frozen_string_literal: true

# Represent a constituent file from a completed Alma publishing job containing a batch of xml records
class BatchFile < ApplicationRecord
  include Statuses

  belongs_to :alma_export

  validates :status, inclusion: Statuses::ALL, presence: true
  validates :path, presence: true

  scope :filter_search, ->(query) { where('path ILIKE :search', search: "%#{query}%") }
  scope :filter_status, ->(status) { where(status: status) }
  scope :filter_sort_by, ->(value, order) { order("#{value}": order) }
end
