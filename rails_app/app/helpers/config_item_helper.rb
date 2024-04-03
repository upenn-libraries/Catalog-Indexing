# frozen_string_literal: true

# helper methods for ConfigItems
module ConfigItemHelper
  # Render the form partial for a boolean field
  #
  # @param config_item [ConfigItem]
  def boolean_form(config_item:)
    render partial: 'config_items/boolean', locals: { config_item: config_item }
  end

  # Render a form for a string or array field
  #
  # @param config_item [ConfigItem]
  # @param selected [String|Array] currently selected element(s) from the options
  # @param multiple [Boolean] whether the select is multiple or single select
  def select_form(config_item:, selected: [], multiple: false)
    options_method = ConfigItem::DETAILS[config_item.name.to_sym][:options_method]
    options = send(options_method, selected)
    render partial: 'config_items/select', locals: { config_item: config_item,
                                                     options: options,
                                                     multiple: multiple }
  end

  # Get currently available collections from Solr for rendering in a form select
  #
  # @param selected [String|Array] pre-selected values
  def available_collections(selected)
    collections = Solr::Admin.new.all_collections
    options_for_select(collections, selected)
  end
end
