# frozen_string_literal: true

# actions for displaying an AlmaExport's batch files
class BatchFilesController < ApplicationController
  before_action :set_alma_export, only: %i[index show]
  before_action :set_batch_file, only: %i[show]

  def index
    @batch_files = @alma_export.batch_files
  end

  def show; end

  private

  def set_alma_export
    @alma_export = AlmaExport.find(params[:alma_export_id])
  end

  def set_batch_file
    @batch_file = @alma_export.batch_files.find(params[:id])
  end
end

