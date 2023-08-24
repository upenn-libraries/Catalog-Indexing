# frozen_string_literal: true

module FixtureHelpers
  # @param [String] filename
  # @return [String]
  def marc_fixture(filename)
    filename = "#{filename}.xml" unless filename.ends_with?('.xml')
    File.read(File.join(fixture_path, 'marc_xml', filename))
  end
end