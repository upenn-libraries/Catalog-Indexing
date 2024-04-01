# frozen_string_literal: true

# helper methods for ConfigItems
module ConfigItemHelper
  def boolean_form(config_item:)
    render partial: 'config_items/boolean', locals: { config_item: config_item }
  end

  def select_form(config_item:, multiple: false)
    options_method = ConfigItem::LIST[config_item.name.to_sym][:options_method]
    render partial: 'config_items/select', locals: { config_item: config_item,
                                                     options: send(options_method),
                                                     multiple: multiple }
  end

  def available_collections
    Solr::Admin.new.all_collections
  end
end
