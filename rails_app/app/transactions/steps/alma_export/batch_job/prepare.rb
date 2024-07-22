# frozen_string_literal: true

module Steps
  module AlmaExport
    module BatchJob
      # Build a Sidekiq::Batch job to populating later, with desired callback events declared
      class Prepare
        include Dry::Monads[:result]

        # @param alma_export [AlmaExport]
        # @return [Dry::Monads::Result]
        def call(alma_export:, **args)
          batch_job = Sidekiq::Batch.new
          batch_job.description = "BatchFile processing jobs for AlmaExport #{alma_export.id}."
          batch_job.on(:success, ::BatchCallbacks::FinalizeAlmaExport, alma_export.id) # all succeed
          batch_job.on(:complete, ::BatchCallbacks::FinalizeAlmaExport, alma_export.id) # all have run
          Success(alma_export: alma_export, batch_job: batch_job, **args)
        end
      end
    end
  end
end
