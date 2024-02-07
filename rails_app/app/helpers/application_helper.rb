# frozen_string_literal: true

# Base Application helper
module ApplicationHelper
  # @return [String]
  def solr_admin_url
    ENV.fetch('SOLR_ADMIN_URL', nil)
  end
end
