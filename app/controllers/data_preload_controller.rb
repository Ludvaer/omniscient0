class DataPreloadController < ApplicationController
  def preload
    request_data = params.require(:data).permit!
    recursive = true; # params[:recursive] == "true"  # Check if recursive loading is enabled
    response_data = {}
    # initialize a hash to keep track of already requested objcts
    requested_data = request_data.each.map{|type,array|[type, array.to_set]}.to_h
    # initialize a hash to keep next batch of objects and not mixing them with request_data_next
    request_data_next = {}
    # Process the queue until there are no more models/ids to load
    while request_data.each.map{|type,array|array}.flatten.any?
       request_data.each do |current_type, ids|
         puts "(#{current_type}):[#{ids}]"
         model_class = current_type.to_s.constantize
         records = model_class.where(id: ids)
         # Check if the model is a container
         if model_class.is_container
           associations = model_class.contained_associations
           records = records.includes(*associations)

           records_hash = records.each_with_object({}) do |record, hash|
             #preloadable_attributes contains filtered attributes
             record_data = record.preloadable_attributes
             # Add contained association ids
             associations.each do |association|
               related_ids = record.public_send(association).pluck(:id)
               record_data["#{association.to_s.singularize}_ids"] = related_ids

               # If recursive, queue related objects for loading
               if recursive
                 related_class = association.to_s.singularize.camelize.constantize
                 #class name starts with capital
                 class_name = association.to_s.singularize.capitalize
                 #filter already requested id
                 requested_data[class_name] ||= [].to_set
                 related_ids.filter!{|id| !requested_data[class_name].include?(id) }
                 #init and add rest of id for next request
                 request_data_next[class_name] ||= [].to_set
                 request_data_next[class_name].merge(related_ids)
                 # also mark as requested
                 requested_data[class_name].merge(related_ids)
               end
             end

             hash[record.id] = record_data
           end
         else
           # For non-container types, load basic attributes
           records_hash = records.index_by(&:id).transform_values(&:preloadable_attributes)
         end

         # Add records to response
         response_data[current_type] ||= {}
         response_data[current_type].merge!(records_hash)

         # Handle belongs_to associations if recursive loading is enabled
         if recursive
           model_class.reflect_on_all_associations(:belongs_to).each do |association|
             associated_class = association.class_name.constantize
             associated_ids = records.pluck(association.foreign_key).compact.uniq
             #filter already requested id
             requested_data[association.class_name] ||= [].to_set
             associated_ids.filter!{|id| !requested_data[association.class_name].include?(id) }
             # add for requests on next iteration
             request_data_next[association.class_name] ||= [].to_set
             request_data_next[association.class_name].merge(associated_ids)
             # also mark as requested
             requested_data[association.class_name].merge(associated_ids)
           end
         end
       end
       #set request_data_next as next objects to load
       request_data = request_data_next
       #new empty hash to store not loaded objects
       request_data_next = {}
       #requested_data keeps accumulating all edded to request object over iterations
    end

    # Render the complete data tree as JSON
    render json: response_data
  end
end
