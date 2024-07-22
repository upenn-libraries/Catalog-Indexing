# frozen_string_literal: true

module Steps
  module AlmaExport
    module BatchJob
      # Step to populate a batch job with ProcessBatchFile jobs
      class Populate
        include Dry::Monads[:result]

        # Stuff a Sidekiq::Batch with ProcessBatchFile jobs
        # @param [AlmaExport] alma_export
        # @param [Sidekiq::Batch] batch_job
        # @param [Array<BatchFile>] batch_files
        # @return [Dry::Monads::Result]
        def call(alma_export:, batch_job:, batch_files:, **args)
          batch_job.jobs do
            Sidekiq::Client.push_bulk('class' => ProcessBatchFileJob,
                                      'args' => batch_files.map { |bf| [bf.id] })
          end
          Success(alma_export: alma_export, **args)
        end
      end
    end
  end
end
