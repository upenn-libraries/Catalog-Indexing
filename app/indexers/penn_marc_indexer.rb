# frozen_string_literal: true

# Traject Indexer for Penn's Alma MARC
class PennMarcIndexer < Traject::Indexer
  configure do
    define_all_fields
  end

  # shortcut for defining a simple field with appropriate handling for return type
  # see: https://rubydoc.info/gems/traject/3.5.0/file/doc/indexing_rules.md
  def define_field(name, parser_method = nil)
    parser_signal = parser_method || name
    raise ArgumentError unless parser.respond_to? parser_signal.to_sym

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
    search_fields
    sort_fields
    date_fields
    stored_fields
    marc_field
  end

  def identifier_fields
    define_field :id, :identifier_mmsid
    define_field :oclc_id_ss, :identifier_oclc_id
    define_field :doi_ss, :identifier_doi_show
    define_field :isbn_ss, :identifier_isbn_show
    define_field :issn_ss, :identifier_issn_show
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
    define_field :isxn_search, :identifier_isxn_search
  end

  def sort_fields
    define_field :creator_sort
    define_field :title_sort
  end

  def date_fields
    to_field('publication_date_s') do |record, acc|
      pub_date = parser.public_send :date_publication, record
      acc << (pub_date.strftime('%Y') || '') # e.g., 1999
    end
    to_field('date_added_s') do |record, acc|
      date_added = parser.public_send :date_added, record
      acc << (date_added.strftime('%F') || '') # e.g., 1999-1-30
    end
  end

  # TODO: many of these stored fields will eventually be replaced by dynamic methods parsing stored MARCXML in the
  #       catalog front end
  def stored_fields
    define_field :creator_ss, :creator_show
    define_field :format_ss, :format_show
    define_field :edition_ss, :edition_show
    define_field :series_ss, :series_show
    define_field :subject_ss, :subject_show
    define_field :mesh_subject_ss, :subject_medical_show
    define_field :local_subject_ss, :subject_local_show
    define_field :genre_ss, :genre_show
    define_field :place_of_pub_ss, :production_place_of_publication_show
    define_field :language_ss, :language_show
    define_field :notes_ss, :notes_notes_show
  end

  def marc_field
    # TODO: use a marcxml-specific field type to make this reasonably searchable
    to_field('marcxml_ss') do |record, acc|
      acc << MARC::FastXMLWriter.encode(PlainMarcRecord.new(record))
    end
  end
end
