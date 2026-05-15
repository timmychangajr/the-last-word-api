class RoomsController < ApplicationController
  def create
    room = Room.create!
    render json: { room_code: room.code, target_quote: room.target_quote }
  end

  def show
    room = Room.find_by(code: params[:code].upcase)
    if room
      users = room.users || []
      if users.size >= 4
        render json: { error: "Lobby is full" }, status: :forbidden
        return
      end

      render json: { buffer: room.buffer_array, target_quote: room.target_quote }
    else
      render json: { error: "Room not found" }, status: :not_found
    end
  end
end
