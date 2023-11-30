class AdminUser < ActiveRecord::Base

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates_presence_of :auth_level

  scope :moderators, -> { 
    where('auth_level = ?', 'moderator')
  }

  def name
    "#{first_name} #{last_name}"
  end

end
