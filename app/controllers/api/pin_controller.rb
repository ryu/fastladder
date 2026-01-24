class Api::PinController < ApplicationController
  before_action :login_required_api
  params_required %i[link title], only: :add
  params_required :link, only: :remove
  skip_before_action :verify_authenticity_token

  module ErrorCode
    NOT_FOUND = 2
  end

  def all
    render json: current_member.pins
  end

  def add
    link = params[:link]
    title = params[:title]
    pin = current_member.pins.create(link: link, title: title)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("pin-count", html: current_member.pins.count.to_s),
          turbo_stream.append("pins-list", partial: "api/pin/pin", locals: { pin: pin })
        ]
      end
      format.json { render_json_status(true) }
      format.any { render_json_status(true) }
    end
  end

  def remove
    pin = current_member.pins.find_by(link: params[:link])
    unless pin
      respond_to do |format|
        format.turbo_stream { head :not_found }
        format.json { render_json_status(false, ErrorCode::NOT_FOUND) }
        format.any { render_json_status(false, ErrorCode::NOT_FOUND) }
      end
      return
    end

    pin_id = pin.id
    pin.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("pin-count", html: current_member.pins.count.to_s),
          turbo_stream.remove("pin-#{pin_id}")
        ]
      end
      format.json { render_json_status(true) }
      format.any { render_json_status(true) }
    end
  end

  def clear
    current_member.pins.destroy_all

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("pin-count", html: "0"),
          turbo_stream.update("pins-list", html: "")
        ]
      end
      format.json { render_json_status(true) }
      format.any { render_json_status(true) }
    end
  end
end
