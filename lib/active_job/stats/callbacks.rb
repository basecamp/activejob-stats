module ActiveJob
  module Stats
    module Callbacks
      extend ActiveSupport::Concern

      included do
        before_enqueue ->(job) { after_enqueue_stats(job) }, if: :monitored
        after_enqueue  ->(job) { after_enqueue_stats(job) },  if: :monitored
        before_perform ->(job) { before_perform_stats(job) }, if: :monitored
        after_perform  ->(job) { after_perform_stats(job) },  if: :monitored
        around_perform ->(job, block) { benchmark_stats(job, block) },      if: :benchmarked

        private

        def benchmark_stats(job, block)
          require 'active_support/core_ext/benchmark'
          benchmark = Benchmark.ms { block.call }
          ActiveJob::Stats.reporter.timing("#{job.queue_name}.processed", benchmark)
          ActiveJob::Stats.reporter.timing("#{job.class}.processed", benchmark)
          ActiveJob::Stats.reporter.timing("#{job.class}.#{ENV['RAILS_ENV']}.processed", benchmark)
        end

        def before_perform_stats(job)
          ActiveJob::Stats.reporter.increment("#{job.queue_name}.started")
          ActiveJob::Stats.reporter.increment("#{job.class}.started")
          ActiveJob::Stats.reporter.increment("#{job.class}.#{ENV['RAILS_ENV']}.started")
          ActiveJob::Stats.reporter.increment('total.started')
        end

        def after_enqueue_stats(job)
          ActiveJob::Stats.reporter.increment("#{job.queue_name}.enqueued")
          ActiveJob::Stats.reporter.increment("#{job.class}.enqueued")
          ActiveJob::Stats.reporter.increment("#{job.class}.#{ENV['RAILS_ENV']}.enqueued")
          ActiveJob::Stats.reporter.increment('total.enqueued')
        end

        def after_perform_stats(job)
          ActiveJob::Stats.reporter.increment("#{job.queue_name}.finished")
          ActiveJob::Stats.reporter.increment("#{job.class}.finished")
          ActiveJob::Stats.reporter.increment("#{job.class}.#{ENV['RAILS_ENV']}.finished")
          ActiveJob::Stats.reporter.increment('total.finished')
        end

        delegate :benchmarked, :monitored, to: :class

      end
    end
  end
end
