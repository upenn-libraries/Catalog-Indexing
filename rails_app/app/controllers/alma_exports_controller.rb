# frozen_string_literal: true

# actions for managing AlmaExport info
class AlmaExportsController < ApplicationController
  before_action :load_alma_export, only: %i[show destroy]

  def index
    @alma_exports = AlmaExport.includes(:batch_files)
                              .by_status(filter('status'))
                              .by_full(filter('full'))
                              .apply_sort(sort_field, sort_direction)
                              .page(params[:page])
  end

  def show; end

  def destroy
    @alma_export.destroy

    redirect_to alma_exports_path, alert: "Alma Export ##{@alma_export.id} removed"
  end

  private

  def load_alma_export
    @alma_export = AlmaExport.find params[:id]
  end

  def filter(param)
    params.dig('filter', param)
  end

  def sort_field
    filter('sort_value') if filter('sort_value')&.in? FilterHelper::SORT_FIELDS
  end

  def sort_direction
    filter('sort_order') if filter('sort_order')&.in?(FilterHelper::SORT_DIRECTIONS.map { |dir| dir[1] })
  end
end
