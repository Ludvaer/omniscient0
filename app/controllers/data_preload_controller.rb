class DataPreloadController < ApplicationController
  def preload
    recursive = params[:recursive] == "true"
    render json: DataPreloadService.fetch_data(params[:data], recursive: recursive)
  end
end
