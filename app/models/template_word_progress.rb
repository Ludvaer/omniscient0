class TemplateWordProgress < ApplicationRecord
  belongs_to :template, :class_name => 'PickWordInSetTemplate'
  belongs_to :word
  after_initialize :set_defaults

  def set_defaults
    last_counter ||= 0
    correct ||= 0
    failed ||= 0
  end
end
