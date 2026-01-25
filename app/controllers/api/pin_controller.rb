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

    if turbo_stream_request?
      render turbo_stream: [
        turbo_stream.update("pin-count", html: current_member.pins.count.to_s),
        turbo_stream.append("pins-list", partial: "api/pin/pin", locals: { pin: pin })
      ]
    else
      render_json_status(true)
    end
  end

  def remove
    pin = current_member.pins.find_by(link: params[:link])
    unless pin
      if turbo_stream_request?
        head :not_found
      else
        render_json_status(false, ErrorCode::NOT_FOUND)
      end
      return
    end

    pin_id = pin.id
    pin.destroy

    if turbo_stream_request?
      render turbo_stream: [
        turbo_stream.update("pin-count", html: current_member.pins.count.to_s),
        turbo_stream.remove("pin-#{pin_id}")
      ]
    else
      render_json_status(true)
    end
  end

  def clear
    current_member.pins.destroy_all

    if turbo_stream_request?
      render turbo_stream: [
        turbo_stream.update("pin-count", html: "0"),
        turbo_stream.update("pins-list", html: "")
      ]
    else
      render_json_status(true)
    end
  end
end
