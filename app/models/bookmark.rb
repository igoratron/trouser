class Bookmark < ApplicationRecord
  validates :url_id, presence: true
  validates :url, presence: true, uniqueness: true
  
  # JSON column for storing flexible bookmark content
  # Examples: { title: "Page Title", description: "...", tags: ["tag1", "tag2"] }
  
  before_validation :generate_url_id
  
  private
  
  def generate_url_id
    self.url_id = SecureRandom.alphanumeric(21) if url_id.blank?
  end
end
