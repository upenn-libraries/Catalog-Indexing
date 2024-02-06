# frozen_string_literal: true

# Index to Solr via Alma bib webhooks and Traject
class IndexByBibEventJob < TransactionJob
  def transaction(marc_xml)
    IndexByBibEvent.new.call(docs: marc_xml)
  end
end
