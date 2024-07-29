# frozen_string_literal: true

# actions for managing AlmaExport info
class AlmaExportsController < ApplicationController
  before_action :load_alma_export, only: %i[show destroy]

  def index
    @alma_exports = AlmaExport.all.includes(:batch_files).page(params[:page])
    @alma_exports = @alma_exports.filter_status(filter('status')) if filter('status').present?
    @alma_exports = @alma_exports.filter_full(filter('full')) if filter('full').present?

    return if filter('sort_value').blank?

    sort_order = filter('sort_order').presence || 'desc'
    @alma_exports = @alma_exports.filter_sort_by(filter('sort_value'), sort_order)
  end

  def show; end

  def destroy
    # TODO: under what conditions should we allow #destroy? only if completed? this would end up destroying all child
    #       BatchFiles, which could end up deleting files from local storage and/or SFTP server
    @alma_export.destroy
  end

  private

  def load_alma_export
    @alma_export = AlmaExport.find params[:id]
  end

  def filter(param)
    params.dig('filter', param)
  end
end
