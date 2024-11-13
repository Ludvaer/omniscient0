class DataPreloadController < ApplicationController
  def preload
    request_data = params.require(:data).permit!
    recursive = true; # params[:recursive] == "true"  # Check if recursive loading is enabled
    response_data = {}
    # Initialize a queue to keep track of all models and ids to load
    load_queue = request_data.to_h
    # Process the queue until there are no more models/ids to load
    while load_queue.any?
     current_type, ids = load_queue.shift
     puts "(#{current_type}):[#{ids}]"
     model_class = current_type.to_s.constantize
     records = model_class.where(id: ids)
     # Check if the model is a container
     if model_class.is_container
       associations = model_class.contained_associations
       records = records.includes(*associations)

       records_hash = records.each_with_object({}) do |record, hash|
         record_data = record.attributes

         # Add contained association ids
         associations.each do |association|
           related_ids = record.public_send(association).pluck(:id)
           record_data["#{association.to_s.singularize}_ids"] = related_ids

           # If recursive, queue related objects for loading
           if recursive
             related_class = association.to_s.singularize.camelize.constantize
             load_queue[association.to_s.singularize.capitalize] ||= []
             load_queue[association.to_s.singularize.capitalize].concat(related_ids).uniq!
           end
         end

         hash[record.id] = record_data
       end
     else
       # For non-container types, load basic attributes
       records_hash = records.index_by(&:id).transform_values(&:attributes)
     end

     # Add records to response
     response_data[current_type] ||= {}
     response_data[current_type].merge!(records_hash)

     # Handle belongs_to associations if recursive loading is enabled
     if recursive
       model_class.reflect_on_all_associations(:belongs_to).each do |association|
         associated_class = association.class_name.constantize
         associated_ids = records.pluck(association.foreign_key).compact.uniq

         # Add associated objects to queue if not already loaded
         next if associated_ids.empty? || response_data[association.class_name]&.keys&.include?(associated_ids)

         load_queue[association.class_name] ||= []
         load_queue[association.class_name].concat(associated_ids).uniq!
       end
     end
    end

    # Render the complete data tree as JSON
    render json: response_data
  end
end
