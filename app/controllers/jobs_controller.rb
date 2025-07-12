class JobsController < ApplicationController
  before_action :ensure_development

  def status
    @job_stats = {
      total_jobs: SolidQueue::Job.count,
      pending_jobs: SolidQueue::Job.where(finished_at: nil).count,
      completed_jobs: SolidQueue::Job.where.not(finished_at: nil).count,
      failed_jobs: SolidQueue::FailedExecution.count,
      ready_executions: SolidQueue::ReadyExecution.count,
      claimed_executions: SolidQueue::ClaimedExecution.count,
      scheduled_executions: SolidQueue::ScheduledExecution.count
    }
    
    @recent_jobs = SolidQueue::Job.order(created_at: :desc).limit(10)
    @failed_jobs = SolidQueue::FailedExecution.order(created_at: :desc).limit(5)
    @processes = SolidQueue::Process.all
  end

  private

  def ensure_development
    redirect_to root_path unless Rails.env.development?
  end
end