class TemplateProgress < ApplicationRecord
  belongs_to :template, :class_name => 'PickWordInSetTemplate'
  after_initialize :set_defaults

  def set_defaults
    counter ||= 0
  end
end
