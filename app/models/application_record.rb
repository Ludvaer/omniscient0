class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  def self.is_container
    false
  end
end
