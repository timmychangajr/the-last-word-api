# Manages room state updates: scores, progress, buffer, win conditions
class GameStateManager
  BUFFER_SIZE = 15

  def self.update_room_state(room, username, points, progress, is_correct, word, msg)
    target_size = room.words.size

    # Update user score and progress
    room.users = room.users.map do |u|
      if u["username"] == username
        u["score"] += points
        u["progress"] = progress
        if is_correct && !u["completed_indices"].include?(progress - 1)
          u["completed_indices"] << (progress - 1)
        end
      end
      u
    end

    if is_correct
      room.buffer_array << {
        "word" => word,
        "username" => username,
        "message" => msg,
        "progress_at_time" => progress - 1,
        "health" => word.length * 2
      }
      room.buffer_array = room.buffer_array.last(BUFFER_SIZE)
    end

    # Check if game is won
    if any_players_finished?(room, target_size) && room.winner.blank?
      winning_name = highest_scorer(room)
      room.winner = winning_name

      winners = winning_name.split(",")

      # Map to a fresh array and re-assign it explicitly
      room.users = room.users.map do |u|
        # We use .dup or .merge to ensure we aren't just modifying
        # the same memory object Rails is already tracking
        if winners.include?(u["username"])
          u.merge("wins" => (u["wins"] || 0) + 1)
        else
          u
        end
      end
    end

    room.save!
  end

  def self.update_user_stat(room, name, pts, prog = nil)
    room.users = room.users.map do |u|
      if u["username"] == name
        u["score"] += pts
        u["progress"] = prog unless prog.nil?
      end
      u
    end
  end

  def self.any_players_finished?(room, target_size)
    room.users.any? { |u| u["progress"] >= target_size }
  end

  def self.highest_scorer(room)
    max_score = room.users.map { |u| u["score"] }.max
    tied_players = room.users.select { |u| u["score"] == max_score }.map { |u| u["username"] }
    tied_players.join(",")
  end

  def self.other_player_at_slot?(room, username, slot)
    room.buffer_array.any? { |e| e["progress_at_time"] == slot && e["username"] != username }
  end
end
