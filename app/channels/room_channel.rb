class RoomChannel < ApplicationCable::Channel
  # ============================================================================
  # PUBLIC CHANNEL ACTIONS
  # ============================================================================

  def subscribed
    @room = Room.find_by(code: params[:code])
    @username = params[:username]
    return reject unless @room && @username

    stream_from "room_#{@room.code}"

    @room.with_lock do
      current_users = @room.users || []

      unless current_users.any? { |u| u["username"] == @username }
        # Logic to see if they should join as 'ready'
        game_in_progress = @room.winner.nil? && (
          (current_users.length >= 2 && current_users.all? { |u| u["ready"] }) ||
          current_users.any? { |u| u["progress"] > 0 }
        )

        updated_users = current_users + [ {
          "username" => @username,
          "score" => 0,
          "wins" => 0,
          "progress" => 0,
          "completed_indices" => [],
          "ready" => game_in_progress
        } ]

        @room.update!(users: updated_users)
      end
    end

    broadcast_state
  end

  def receive_word(data)
    @room.with_lock do
      word, username = data["word"].strip, data["username"]
      target = @room.words

      user = @room.users.find { |u| u["username"] == username }
      return unless user

      points, is_correct, msg = WordScorer.calculate_score(word, user, target)
      if is_correct && !user["completed_indices"].include?(user["progress"])
        # Check if user is the first one to put a word in this slot
        unless GameStateManager.other_player_at_slot?(@room, username, user["progress"])
          points += 2
          msg = "Sleight of Hand! (+2)"
        end
      end

      new_progress = is_correct ? user["progress"] + 1 : user["progress"]

      GameStateManager.update_room_state(@room, username, points, new_progress, is_correct, word, msg)

      # If the game ended, reset ready states
      if @room.winner.present?
        @room.update!(users: @room.users.map { |u| u.merge("ready" => false) })
      end

      broadcast_state({ username: username, points: points, message: msg, word: word, id: Time.now.to_f })
    end
  end

  def penalize_word(data)
    @room.with_lock do
      target_user, progress = data["target_username"], data["progress_at_time"]
      idx = @room.buffer_array.find_index { |e| e["username"] == target_user && e["progress_at_time"] == progress }
      return unless idx

      entry = @room.buffer_array[idx]
      entry["health"] -= 1

      # Check if word is destroyed (health dropped to 0 or below)
      if entry["health"] <= 0
        # Remove word and all subsequent words by same player
        @room.buffer_array.delete_at(idx)
        @room.buffer_array.reject! { |e| e["username"] == target_user && e["progress_at_time"] > progress }

        # Reset player progress to this slot
        GameStateManager.update_user_stat(@room, target_user, -1, progress)
        msg = "Word destroyed!"
      else
        GameStateManager.update_user_stat(@room, target_user, -1)
        msg = "Hit!"
      end

      @room.save!
      broadcast_state({ username: target_user, points: -1, message: msg, word: entry["word"], id: Time.now.to_f })
    end
  end

  def player_ready(data)
    @room.with_lock do
      username = data["username"]

      # Mark player as ready while preserving their score
      updated_users = @room.users.map do |u|
        u["username"] == username ? u.merge("ready" => true) : u
      end

      # If all players ready and at least 2 players, start new round
      if GameRoundManager.should_start_new_round?(updated_users)
        GameRoundManager.start_new_round(@room, updated_users)
      else
        @room.update!(users: updated_users)
        broadcast_state
      end
    end
  end

  def unsubscribed
    return unless @room

    @room.with_lock do
      new_users = @room.users.reject { |u| u["username"] == @username }

      if new_users.empty?
        @room.destroy
        return
      end

      game_in_progress = @room.winner.nil? && @room.users.any? { |u| u["ready"] }
      @room.update(users: new_users) unless game_in_progress
    end
    broadcast_state
  end

  # ============================================================================
  # PRIVATE HELPERS
  # ============================================================================

  private

  def broadcast_state(feedback = nil)
    return unless @room

    ActionCable.server.broadcast("room_#{@room.code}", {
      buffer: @room.buffer_array.sort_by { |e| e["progress_at_time"] },
      users: @room.users,
      winner: @room.winner,
      target_quote: @room.target_quote,
      score_feedback: feedback
    })
  end
end
