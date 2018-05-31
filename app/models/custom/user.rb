require_dependency Rails.root.join('app', 'models', 'user').to_s

class User < ActiveRecord::Base
  has_one :consultant

  scope :consultants,  -> { joins(:consultant) }

  def consultant?
    consultant.present?
  end
end
