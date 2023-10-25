# frozen_string_literal: true

require 'dry/transaction'

# with an Array of MMSIDs as a parameter, get MARCXML from the Alma API and index via Traject
class IndexByIdentifier
  include Dry::Transaction(container: Container)

  step :retrieve_marcxml, with: 'marcxml.retrieve' # get MARCXML from Alma API
  step :prepare_marcxml, with: 'marcxml.prepare' # massage MARCXML
  step :index_via_traject, with: 'traject.index_records' # receive a IO object and do the indexing
end
