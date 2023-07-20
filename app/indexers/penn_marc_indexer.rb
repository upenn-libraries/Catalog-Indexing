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
  def define_field(name, parser_method)
    raise unless name && parser_method
    raise unless parser.respond_to? parser_method.to_sym

    to_field(name.to_s) { |record, accumulator| accumulator << parser.public_send(parser_method.to_sym, record) }
  end

  def parser
    @parser ||= PennMARC::Parser.new
  end

  def define_all_fields
    identifier
    title
    subjects
    genre
    note
  end

  def titles
    define_field 'title_display', :title_show
  end

  def identifiers
    define_field 'id', :identifier_mmsid
  end

  def subjects; end
  def genres; end
  def notes; end
end
