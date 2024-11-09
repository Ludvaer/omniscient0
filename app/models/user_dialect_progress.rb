class UserDialectProgress < ApplicationRecord
  belongs_to :user
  belongs_to :dialect
  belongs_to :source_dialect, :class_name => 'Dialect'
  after_initialize :set_defaults

  def set_defaults
    counter ||= 0
  end
end
