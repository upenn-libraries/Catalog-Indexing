# frozen_string_literal: true

module FixtureHelpers
  # @param [String] filename
  # @return [String]
  def marc_fixture(filename)
    filename = "#{filename}.xml" unless filename.ends_with?('.xml')
    File.read(File.join(fixture_paths, 'marc_xml', filename))
  end

  # @param [String] filename
  # @return [String]
  def json_fixture(filename, directory = nil)
    filename = "#{filename}.json" unless filename.ends_with?('.json')
    dirs = ['json', directory.to_s, filename].compact_blank
    File.read(File.join(fixture_paths, dirs))
  end
end
