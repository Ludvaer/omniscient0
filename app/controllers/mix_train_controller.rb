class MixTrainController < ApplicationController
  # mix train stands for mixed training,
  # the training that consists al multiple, possible all available trainning types mixed together
  #
  include MixTrainHelper
  include SessionsHelper

  def new
    @user = current_user
    @n = params[:n]
    @source_dialect_id = params[:source_dialect_id]
    @target_dialect_id = params[:target_dialect_id]
    # params[:current_user] = @user
    @recursive = params[:recursive] || @recursive == 'false' || false
    @train_list = mix_train_list(@source_dialect_id, @target_dialect_id, @n)
    @data_request = mix_train_create(@train_list, @user)
    @data =  DataPreloadService.fetch_data(@data_request, recursive: true);
    respond_to do |format|
      unless @data.blank? #TODO: make it proper check for all values to be blank
        format.html { render :new, notice: 'objects are created but display is not implemented'}
        format.json { render json: @data, status: :created, location: '' }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @data.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
  end

  def render_form_partial
    @user = current_user
    model_name = params[:model_name]
    # object_id = params[:id]
    object = model_name.constantize.new  # .find(object_id)
    ids = params[:ids] || ( params[:id] ?  [params[:id]]  : [] )
    if model_name
      html = render_to_string(partial: "#{model_name.underscore.pluralize}/form", \
      locals: {  model_name.underscore.to_sym => object, locals: {activated: true, ids: ids, params: params}})
      render json: { html: html }, status: :ok
    else
      render json: { error: "Object not found" }, status: :not_found
    end
  end
end
