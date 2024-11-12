class DataPreloadController < ApplicationController


  def preload
    # Parse the incoming JSON payload
    request_data = params.require(:data).permit!
    puts " model_clas = #{request_data}"
    # Initialize a response hash
    response_data = {}

    # Iterate through each type in the incoming request
    request_data.each do |type_name, ids|
      # Use the constantize method to convert the type name into a model class
      model_class = type_name.constantize
      puts "#{type_name} model_class"
      # Query the database for records with the given ids
      records = model_class.where(id: ids)
      puts "#{type_name} records"
      # Detect if the class is a "Set" type (contains elements of a different model)
      if type_name.to_s.end_with?("Set")
        puts "#{type_name} ends with Set"
        # Infer associated model by removing the "Set" suffix
        associated_model_name = type_name.chomp("Set")

        puts "associated_model_name = #{associated_model_name}"
        # Convert to lowercase and pluralize for relationship inference
        associated_relation = associated_model_name.underscore.pluralize
        puts "associated_relation = #{associated_relation}"
        # Check if the association exists to ensure robustness
        if model_class.reflect_on_association(associated_relation.to_sym)
          # Preload the inferred association
          records = records.includes(associated_relation.to_sym)
          puts "records = #{records}"
          # Convert records to a hash with associated ids
          records_hash = records.each_with_object({}) do |record, hash|
            # Build a hash with attributes and add associated ids
            hash[record.id] = record.attributes.merge(
              "#{associated_relation.singularize}_ids": record.public_send(associated_relation).pluck(:id)
            )
          puts "records_hash = #{records_hash}"
          end
        else
          # If no association is found, fall back to attributes only
          records_hash = records.index_by(&:id).transform_values(&:attributes)
        end
      else
        puts "#{type_name} ends not with Set"
        # For non-Set types, load attributes only
        records_hash = records.index_by(&:id).transform_values(&:attributes)
      end

      # # Convert records to a hash with id as keys
      # records_hash = records.index_by(&:id).transform_values(&:attributes)

      # Add the results to the response hash
      response_data[type_name] = records_hash
    end

    # Render the response as JSON
    render json: response_data
  end
end
