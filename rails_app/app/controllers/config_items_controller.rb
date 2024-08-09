# frozen_string_literal: true

# actions for displaying and modifying configuration items
class ConfigItemsController < ApplicationController
  before_action :set_config_item, only: :update

  def index
    @config_items = ConfigItem.order(config_type: :desc, name: :asc)
  end

  def update
    @config_item.value = value_from params
    flash.notice = save_and_set_message(@config_item)
    redirect_to config_items_path
  end

  private

  def set_config_item
    @config_item = ConfigItem.find(params[:id])
  end

  # @param config_item [ConfigItem]
  def save_and_set_message(config_item)
    if config_item.save
      "Value updated for #{config_item.name}"
    else
      "Problem updating value for #{config_item.name}: #{config_item.errors.map(&:full_message).join(', ')}"
    end
  end

  # Massage param values into appropriate data structure for storage in PG JSON field
  # @param params [ActionController::Parameters]
  def value_from(params)
    value = params[@config_item.name]
    case @config_item.config_type
    when ConfigItem::BOOLEAN_TYPE
      value == '1'
    else
      value
    end
  end
end
