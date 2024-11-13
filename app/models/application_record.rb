class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  SKIP_ATTRIBUTES = ['created_at', 'updated_at', 'password_digest', 'password', 'token'].to_set

  def self.is_container
    false
  end

  def preloadable_attributes
    attributes.filter{|x,y| !(x in SKIP_ATTRIBUTES)}
  end
end
