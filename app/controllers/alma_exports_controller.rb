# frozen_string_literal: true

# actions for managing AlmaExport info
class AlmaExportsController < ApplicationController
  before_action :load_alma_export, only: %i[show destroy]

  def index
    @alma_exports = AlmaExport.all.includes(:batch_files).page(params[:page])
    @alma_exports = @alma_exports.filter_status(params.dig('filter', 'status')) if params.dig('filter', 'status').present?
    if params.dig('filter', 'sort_value').present? && params.dig('filter', 'sort_order').present?
      @alma_exports = @alma_exports.filter_sort_by(params.dig('filter', 'sort_value'), params.dig('filter', 'sort_order'))
    end
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
end
