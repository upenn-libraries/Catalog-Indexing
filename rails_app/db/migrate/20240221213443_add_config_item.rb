# frozen_string_literal: true

# Create ConfigItem table
class AddConfigItem < ActiveRecord::Migration[7.1]
  def change
    create_table :config_items do |t|
      t.string :name
      t.string :config_type
      t.jsonb :value
      t.timestamps

      t.index :name, unique: true
    end
  end
end
