class Bookmark < ApplicationRecord
  validates :url_id, presence: true
  validates :url, presence: true, uniqueness: true
  
  before_validation :generate_url_id
  
  private
  
  def generate_url_id
    self.url_id = SecureRandom.alphanumeric(21) if url_id.blank?
  end
end
