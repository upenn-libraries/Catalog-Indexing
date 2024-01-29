# frozen_string_literal: true

# Index to Solr via Alma bib webhooks and Traject
class IndexByBibEventJob
  include Sidekiq::Job

  sidekiq_options queue: 'low'

  def perform(marc_xml)
    IndexByBibEvent.new.call(docs: marc_xml)
  end
end
