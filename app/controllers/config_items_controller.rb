# frozen_string_literal: true

# actions for displaying an AlmaExport's batch files
class ConfigItemsController < ApplicationController
  def index
    @config_items = ConfigItem.all
  end

  def update
    # update the rows in the database based on the form submission
  end
end
