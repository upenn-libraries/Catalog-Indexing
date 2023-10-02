# frozen_string_literal: true

# helper methods for filtering
module FilterHelper
  # When filtering, we want to display nice values to the user, but submit parseable values to the controller. This
  # function makes values in an array pretty and maps them to the parseable values in a hash.
  def titleize_and_hash(options)
    options.filter_map { |original_string|
      [original_string.titleize, original_string]
    }.to_h
  end
end
