class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  SKIP_ATTRIBUTES = ['created_at', 'updated_at', 'password_digest', 'password', 'token'].to_set
  def self.preloadable_fake_references
    {}
  end

  def self.is_container
    false
  end

  def preloadable_attributes
    attributes.reject{|x,y|SKIP_ATTRIBUTES.include?(x)}
  end

end
