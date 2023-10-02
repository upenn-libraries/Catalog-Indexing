# frozen_string_literal: true

# actions for displaying an AlmaExport's batch files
class BatchFilesController < ApplicationController
  before_action :load_alma_export, only: %i[index show]
  before_action :load_batch_file, only: %i[show]

  def index
    @batch_files = @alma_export.batch_files.page(params[:page])
    @batch_files = @batch_files.filter_search(params.dig('filter', 'search')) if params.dig('filter', 'search').present?
    @batch_files = @batch_files.filter_status(params.dig('filter', 'status')) if params.dig('filter', 'status').present?
    if params.dig('filter', 'sort_value').present? && params.dig('filter', 'sort_order').present?
      @batch_files = @batch_files.filter_sort_by(params.dig('filter', 'sort_value'), params.dig('filter', 'sort_order'))
    end
  end

  def show; end

  private

  def load_alma_export
    @alma_export = AlmaExport.find(params[:alma_export_id])
  end

  def load_batch_file
    @batch_file = @alma_export.batch_files.find(params[:id])
  end
end
