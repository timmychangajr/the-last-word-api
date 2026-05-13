class Room < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :target_quote, presence: true

  before_validation :set_defaults, on: :create

  def words
    target_quote.split
  end

  private

  def set_defaults
    self.code ||= generate_unique_code
    self.buffer_array ||= []
    self.users ||= []
    self.target_quote ||= select_random_quote
  end

  def generate_unique_code
    loop do
      code = SecureRandom.alphanumeric(6).upcase
      break code unless Room.exists?(code: code)
    end
  end

  def select_random_quote
    Quote.order("RANDOM()").first&.text || "Default quote"
  end
end
