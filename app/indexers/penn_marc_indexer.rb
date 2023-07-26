# frozen_string_literal: true

# Traject Indexer for Penn's Alma MARC
class PennMarcIndexer < Traject::Indexer
  configure do
    settings do
      # TODO: settings
    end
    define_all_fields
  end

  # shortcut for defining a simple field
  # TODO: modify PennMARC to use "default" mappers so they need not be specified here
  def define_field(name, parser_method = nil)
    raise unless name && parser_method
    raise unless parser.respond_to? parser_method.to_sym

    to_field(name.to_s) { |record, acc| acc << parser.public_send((parser_method || name).to_sym, record) }
  end

  def parser
    @parser ||= PennMARC::Parser.new
  end

  def define_all_fields
    identifier_fields
    facet_fields
    search_fields
    sort_fields
    date_fields
    stored_fields
    marc_field
  end

  def identifier_fields
    define_field :id, :identifier_mmsid
    define_field :oclc_id_ss, :identifier_oclc_id
    define_field :isbn_isxn
  end

  def facet_fields
    define_field :creator_facet
    define_field :format_facet
    define_field :subject_facet
    define_field :genre_facet
    define_field :language_facet, :language_search
    define_field :location_facet, :location_specific_location
    define_field :library_facet, :location_library
  end

  def search_fields
    define_field :creator_search
    define_field :title_search
    define_field :subject_search
    define_field :genre_search
    define_field :isxn_search
  end

  def sort_fields
    define_field :creator_sort
    define_field :title_sort
  end

  def date_fields; end

  def stored_fields; end

  def marc_field; end
end
