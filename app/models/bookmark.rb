class Bookmark < ApplicationRecord
  validates :url_id, presence: true
  validates :url, presence: true, uniqueness: true
  
  # JSON column for storing flexible bookmark content
  # Examples: { title: "Page Title", description: "...", tags: ["tag1", "tag2"] }
  
  # Extraction status enum
  enum :extraction_status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }
  
  before_validation :generate_url_id
  
  private
  
  def generate_url_id
    self.url_id = SecureRandom.alphanumeric(21) if url_id.blank?
  end
end
