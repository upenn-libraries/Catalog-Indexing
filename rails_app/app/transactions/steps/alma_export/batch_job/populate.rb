# frozen_string_literal: true

module Steps
  module AlmaExport
    module BatchJob
      # Step to populate a batch job with ProcessBatchFile jobs
      class Populate
        include Dry::Monads[:result]

        # Stuff a Sidekiq::Batch with ProcessBatchFile jobs
        # @param alma_export [AlmaExport]
        # @param batch_job [Sidekiq::Batch]
        # @param batch_files [Array<BatchFile>]
        # @return [Dry::Monads::Result]
        def call(alma_export:, batch_job:, batch_files:, **args)
          batch_job.jobs do
            ProcessBatchFileJob.perform_bulk batch_files.pluck(:id).zip
          end
          Success(alma_export: alma_export, **args)
        end
      end
    end
  end
end
