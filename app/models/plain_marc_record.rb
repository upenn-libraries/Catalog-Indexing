# frozen_string_literal: true

# This behaves like the wrapped MARC::Record object it contains
# except that the #each method filters out fields with non-standard tags.
class PlainMarcRecord
  VALID_TAG_REGEX = /^\d\d\d$/

  # @param [MARC::Record] record
  def initialize(record)
    @record = record
  end

  def method_missing(*args)
    @record.send(*args)
  end

  def respond_to_missing?(call)
    @record.respond_to? call
  end

  def each
    @record.fields.each do |field|
      yield field if VALID_TAG_REGEX.match?(field.tag)
    end
  end
end
