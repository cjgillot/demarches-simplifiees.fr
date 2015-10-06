class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :dossiers

  def self.find_for_france_connect email
    user = User.find_by_email(email)

    return user unless user.nil?

    User.create(email: email, password: Devise.friendly_token[0,20])
  end
end
