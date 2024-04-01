# frozen_string_literal: true

# actions for displaying and modifying configuration items
class ConfigItemsController < ApplicationController
  def index
    @config_items = ConfigItem.all
  end

  def update
    # update the row in the database based on the form submission values
  end
end
