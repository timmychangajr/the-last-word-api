class Quote < ApplicationRecord
  validates :text, presence: true
end
