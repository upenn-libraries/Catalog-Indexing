# frozen_string_literal: true

# Traject Indexer for Penn's Alma MARC
class PennMarcIndexer < Traject::Indexer
  configure do
    define_all_fields
  end

  # shortcut for defining a simple field with appropriate handling for return type
  # see: https://rubydoc.info/gems/traject/3.5.0/file/doc/indexing_rules.md
  # @todo receive a block to process each value? term override case
  def define_field(name, parser_method = nil)
    parser_signal = parser_method || name
    raise(ArgumentError, "Parser does not respond to #{parser_signal}") unless parser.respond_to? parser_signal.to_sym

    to_field(name.to_s) do |record, acc|
      parser_output = parser.public_send(parser_signal.to_sym, record)
      if parser_output.respond_to?(:each)
        acc.concat(parser_output)
      else
        acc << parser_output
      end
    end
  end

  def parser
    @parser ||= PennMARC::Parser.new
  end

  def define_all_fields
    identifier_fields
    facet_fields
    database_fields
    search_fields
    sort_fields
    date_fields
    stored_fields
    link_fields
    inventory_fields
    marc_field
  end

  def identifier_fields
    define_field :id, :identifier_mmsid
    define_field :oclc_id_ss, :identifier_oclc_id_show
    define_field :doi_ss, :identifier_doi_show
    define_field :isbn_ss, :identifier_isbn_show
    define_field :issn_ss, :identifier_issn_show
  end

  def facet_fields
    to_field 'subject_facet' do |record, acc, _clipboard|
      values = parser.subject_facet(record)
      acc << TermOverrider.process(values: values)
    end

    define_field :access_facet
    define_field :creator_facet
    define_field :format_facet
    define_field :genre_facet
    define_field :classification_facet
    define_field :language_facet, :language_values
    define_field :location_facet, :location_specific_location
    define_field :library_facet, :location_library
  end

  def database_fields
    define_field :db_type_facet, :database_type_facet
    define_field :db_subject_facet, :database_category_facet

    to_field('db_combined_subject_facet') do |record, acc, context|
      acc.concat(parser.public_send(:database_subcategory_facet, record))
      context.clipboard[:db_combined_subjects] = acc
    end

    to_field('db_sub_subject_facet') do |_record, acc, context|
      context.clipboard[:db_combined_subjects].each { |combined_subject| acc << combined_subject.split('--').last }
    end
  end

  def search_fields
    define_field :creator_search
    define_field :creator_aux_search, :creator_search_aux
    define_field :conference_search, :creator_conference_search
    define_field :title_search
    define_field :title_aux_search, :title_search_aux
    define_field :journal_title_search, :title_journal_search
    define_field :journal_title_aux_search, :title_journal_search_aux
    define_field :subject_search
    define_field :genre_search
    define_field :isxn_search, :identifier_isxn_search
    define_field :series_search
  end

  def sort_fields
    define_field :creator_sort
    define_field :title_sort

    to_field('publication_date_sort') do |record, acc|
      pub_date = parser.public_send :date_publication, record
      valid_date?(pub_date) ? acc << pub_date.strftime('%FT%H:%M:%SZ') : acc # e.g., 1999-01-01T00::00::00Z
    end

    to_field('added_date_sort') do |record, acc|
      date = parser.public_send :date_added, record
      valid_date?(date) ? acc << date.strftime('%FT%H:%M:%SZ') : acc # e.g., 1999-01-01T00::00::00Z
    end
  end

  def date_fields
    to_field('publication_date_s') do |record, acc|
      pub_date = parser.public_send :date_publication, record
      acc << (pub_date&.strftime('%Y') || '') # e.g., 1999
    end

    to_field('added_date_s') do |record, acc|
      date_added = parser.public_send :date_added, record
      acc << (date_added&.strftime('%F') || '') # e.g., 1999-1-30
    end
  end

  def stored_fields
    to_field 'subject_ss' do |record, acc|
      values = parser.subject_show(record)
      acc << TermOverrider.process(values: values)
    end

    define_field :title_ss, :title_show
    define_field :format_ss, :format_show
    define_field :creator_ss, :creator_show
    define_field :edition_ss, :edition_show
    define_field :conference_ss, :creator_conference_show
    define_field :series_ss, :series_show
    define_field :publication_ss, :production_publication_show
    define_field :production_ss, :production_show
    define_field :distribution_ss, :production_distribution_show
    define_field :manufacture_ss, :production_manufacture_show
    define_field :contained_within_ss, :relation_contained_in_show
  end

  def link_fields
    to_field('full_text_links_ss') do |record, acc|
      value = parser.link_full_text_links(record)
      acc << json_encode(value) if value.present?
    end
    to_field('web_links_ss') do |record, acc|
      value = parser.link_web_links(record)
      acc << json_encode(value) if value.present?
    end
  end

  def inventory_fields
    # TODO: these fields are likely to be too large for Solr string fields in many cases
    #       leave them out until we have a better context for their usage and make proper accommodations for the size
    # to_field('physical_holdings_json_ss') do |record, acc|
    #   value = parser.inventory_physical(record)
    #   acc << json_encode(value) if value.present?
    # end
    # to_field('electronic_holdings_json_ss') do |record, acc|
    #   value = parser.inventory_electronic(record)
    #   acc << json_encode(value) if value.present?
    # end
    define_field :physical_holding_count_i, :inventory_physical_holding_count
    define_field :electronic_portfolio_count_i, :inventory_electronic_portfolio_count
  end

  def marc_field
    to_field('marcxml_marcxml') do |record, acc|
      acc << MARC::FastXMLWriter.encode(PlainMarcRecord.new(record))
    end
  end

  private

  # Encode a field as JSON
  # @todo implement Oj gem for speedup as needed
  # @param [Object] value
  # @return [String]
  def json_encode(value)
    JSON.generate value
  end

  # Determine if parsed date values are valid
  # @param [Time, nil] date
  # @return [TrueClass, FalseClass]
  def valid_date?(date)
    date.is_a?(Time) && date&.year&.positive?
  end
end
