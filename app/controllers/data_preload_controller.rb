class DataPreloadController < ApplicationController
  def preload
    # Parse the incoming JSON payload
    request_data = params.require(:data).permit!

    # Initialize a response hash
    response_data = {}

    # Iterate through each type in the incoming request
    request_data.each do |type_name, ids|
      # Use the constantize method to convert the type name into a model class
      model_class = type_name.constantize

      # Query the database for records with the given ids
      records = model_class.where(id: ids)

      # Detect if the class is a "Set" type (contains elements of a different model)
      if type_name.end_with?("Set")
       # Infer associated model by removing the "Set" suffix
       associated_model_name = type_name.chomp("Set")

       # Convert to lowercase and pluralize for relationship inference
       associated_relation = associated_model_name.underscore.pluralize

       # Check if the association exists to ensure robustness
       if model_class.reflect_on_association(associated_relation.to_sym)
         # Preload the inferred association
         records = records.includes(associated_relation.to_sym)

         # Convert records to a hash with associated ids
         records_hash = records.each_with_object({}) do |record, hash|
           # Build a hash with attributes and add associated ids
           hash[record.id] = record.attributes.merge(
             "#{associated_relation.singularize}_ids": record.public_send(associated_relation).pluck(:id)
           )
         end
       else
         # If no association is found, fall back to attributes only
         records_hash = records.index_by(&:id).transform_values(&:attributes)
       end
      else
       # For non-Set types, load attributes only
       records_hash = records.index_by(&:id).transform_values(&:attributes)
      end
      # 
      # # Convert records to a hash with id as keys
      # records_hash = records.index_by(&:id).transform_values(&:attributes)

      # Add the results to the response hash
      response_data[type_name] = records_hash
    end

    # Render the response as JSON
    render json: response_data
  end
end
