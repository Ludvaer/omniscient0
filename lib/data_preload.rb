def get_belongs_to_references(model_name)
  # Convert the model name to a class
  model_class = model_name.constantize

  # Initialize a hash to store references and types
  references = {}

  # Iterate through all belongs_to associations
  model_class.reflect_on_all_associations(:belongs_to).each do |association|
    # Store the association name and class name in the references hash
    references[association.name] = association.class_name
  end

  references
end

puts "'PickWordInSet' => #{get_belongs_to_references('PickWordInSet')}"
