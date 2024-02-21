# frozen_string_literal: true

# Create ConfigItem table
class AddConfigItem < ActiveRecord::Migration[7.1]
  def change
    create_table :config_items do |t|
      t.string :name
      t.jsonb :value
      t.timestamps
    end
  end
end
