# frozen_string_literal: true

class PlacesController < ApplicationController
  include UserAgent
  include DecryptedId

  before_action :set_request_variant
  before_action :set_place, only: %i[edit show destroy]

  def index
    respond_to do |format|
      @places = Place.preload(:photos).all.page(params[:page])
      format.html

      format.json { render 'api/places/index' }
    end
  end

  def show
    render partial: 'show', format: :html
  end

  def new
    @place = @current_user.places.build
  end

  def create
    @place = @current_user.places.build(place_params)

    begin
      @place.save!
      redirect_to place_photos_path(place_id: Place.encrypt_id(@place.id.to_s)), notice: '登録しました'
    rescue ActiveRecord::RecordInvalid => e
      @albums = @current_user.places
      # TODO: ここエラーログはログ出力させたいっすね
      logger.error(error_message: e.message)

      render action: :new, alert: '写真の登録に失敗しました'
    end
  end

  def edit; end

  def update; end

  def destroy
    target_date_ymd = @place.created_at_ymd
    @place.destroy

    redirect_to place_photos_path(place_id: Place.encrypt_id(@place.id.to_s), created_at_ymd: target_date_ymd), notice: '写真を削除しました'
  end

  private

  def set_request_variant
    request.variant = :tablet if tablet?
    request.variant = :phone if mobile?
  end

  def set_place
    @place = @current_user.places.find(Place.decrypt_id(params[:id]))
  end

  def place_params
    colums_name = [
      :description,
      photo_attributes: [
        :image
      ],
      tags_attributes: [
        :name
      ]
    ]

    params.require(:place).permit(colums_name)
  end
end