# frozen_string_literal: true

# Class to support removing or replacing string values found in arrays of strings
class TermOverrider
  OVERRIDE_REPLACE_MAP_FILE = 'replace.yml'
  OVERRIDE_REMOVE_VALUES_FILE = 'remove.yml'

  class << self
    # @param values [Array]
    # @return [Array]
    def process(values)
      values.filter_map do |value|
        # Remove values if they contain a remove term
        next nil if value.match?(remove_regex)

        # Replace values using multi_string_replace gem
        MultiStringReplace.replace value, replace_map
      end
    end

    # @return [Hash, nil]
    def replace_map
      @replace_map ||= YAML.safe_load(read_file(OVERRIDE_REPLACE_MAP_FILE))
    end

    # @return [Array, nil]
    def remove_terms
      @remove_terms ||= YAML.safe_load(read_file(OVERRIDE_REMOVE_VALUES_FILE))
    end

    # @return [Regexp]
    def remove_regex
      @remove_regex ||= /#{remove_terms&.join('|')}/i
    end

    # @param filename [String]
    def read_file(filename)
      File.read(Rails.root.join('config', 'term_overrides', filename))
    end
  end
end
