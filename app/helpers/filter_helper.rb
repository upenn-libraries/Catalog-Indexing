# frozen_string_literal: true

# helper methods for filtering
module FilterHelper
  # When filtering, we want to display nice values to the user, but submit parseable values to the controller. This
  # function prettifies values in a given array and pairs them with their parseable values.
  # @param [Array] values
  # @return [Array]
  def titleize_and_pair(values)
    values.filter_map { |value| [value.titleize, value] }
  end
end
