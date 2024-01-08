# frozen_string_literal: true

# helper methods for ConfigItems
module ConfigItemHelper
  def boolean_form(config_item:)
    render partial: 'config_items/boolean', locals: { config_item: config_item }
  end
end
