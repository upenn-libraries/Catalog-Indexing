# frozen_string_literal: true

# actions for displaying an AlmaExport's batch files
class BatchFilesController < ApplicationController
  before_action :load_alma_export, only: %i[index show]
  before_action :load_batch_file, only: %i[show]

  def index
    @batch_files = @alma_export.batch_files
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

