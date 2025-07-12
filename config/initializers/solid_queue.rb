# Solid Queue configuration for single database setup
Rails.application.configure do
  # Configure Active Job to use Solid Queue
  config.active_job.queue_adapter = :solid_queue
  
  # Single database configuration - no separate queue database
  config.solid_queue.connects_to = nil
end

# Set queue configuration
if defined?(SolidQueue)
  SolidQueue.logger = Rails.logger
end