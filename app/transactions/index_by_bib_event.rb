# frozen_string_literal: true

require 'dry/transaction'

# Contains steps to index record received from bib created or updated webhook
class IndexByBibEvent
  include Dry::Transaction(container: Container)

  step :prepare_marcxml, with: 'prepare_marcxml' # massage MARCXML - for now ensure UTF-8
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing
end
