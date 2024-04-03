# frozen_string_literal: true

# helper methods for ConfigItems
module ConfigItemHelper
  def boolean_form(config_item:)
    render partial: 'config_items/boolean', locals: { config_item: config_item }
  end

  def select_form(config_item:, selected: [], multiple: false)
    options_method = ConfigItem::DETAILS[config_item.name.to_sym][:options_method]
    options = send(options_method, selected)
    render partial: 'config_items/select', locals: { config_item: config_item,
                                                     options: options,
                                                     multiple: multiple }
  end

  def available_collections(selected)
    collections = Solr::Admin.new.all_collections
    options_for_select(collections, selected)
  end
end
