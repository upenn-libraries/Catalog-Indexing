# frozen_string_literal: true

# actions for managing Publish Job info
class PublishJobsController < ApplicationController
  before_action :load_publish_job, only: %i[show destroy]

  def index
    @publish_jobs = PublishJob.all.includes(:batch_files) # TODO: add sort/filter functionality
  end

  def show; end

  def destroy
    # TODO: under what conditions should we allow #destroy? only if completed? this would end up destroying all child
    #       BatchFiles, which might end up deleting files from local storage and/or SFTP server
    @publish_job.destroy
  end

  private

  def load_publish_job
    @publish_job = PublishJob.find params[:id]
  end
end
