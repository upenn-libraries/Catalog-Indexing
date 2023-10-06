# frozen_string_literal: true

# actions for displaying an AlmaExport's batch files
class BatchFilesController < ApplicationController
  before_action :load_alma_export, only: %i[index show]
  before_action :load_batch_file, only: %i[show]

  def index
    @batch_files = @alma_export.batch_files.page(params[:page])
    @batch_files = @batch_files.filter_search(filter('search')) if filter('search').present?
    @batch_files = @batch_files.filter_status(filter('status')) if filter('status').present?

    return if filter('sort_value').blank?

    sort_order = filter('sort_order').presence || 'desc'
    @batch_files = @batch_files.filter_sort_by(filter('sort_value'), sort_order)
  end

  def show; end

  private

  def load_alma_export
    @alma_export = AlmaExport.find(params[:alma_export_id])
  end

  def load_batch_file
    @batch_file = @alma_export.batch_files.find(params[:id])
  end

  def filter(param)
    params.dig('filter', param)
  end
end
