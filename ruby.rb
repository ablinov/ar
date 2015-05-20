require 'socket'
require 'set'

words = File.foreach('/usr/share/dict/words')

WORDS_ALREADY_PLAYED = Set.new
BLANK_BOARD = Array.new.fill("00000", 0..4).join(' ')

def can_play_word(board, word)
  return false if WORDS_ALREADY_PLAYED.include?(word)
  result = []
  result_word = ""
  board = board.gsub(/ /, "").chars
  can_play = word.length > 3 && word.chars.all? do |c|
    i = board.index(c); i != nil and ()
    if i != nil
      row = i / 5
      col = i % 5
      result << "#{row}#{col}"
      result_word << board[i]
      board[i] = "$"
    end
    i != nil
  end
  if can_play
    WORDS_ALREADY_PLAYED << result_word
    "move:#{result.join(",")} (#{result_word})"
  else
    false
  end
end

s = TCPSocket.new("52.16.6.95", 4123)
while request = s.gets
  p request

  case request
    when "ping" then
      s.puts "pong\n"
    when "; name ?\n" then
      s.puts "artistsAndRepertoire"
    when /(.*)? ; move ((?:[a-z]{5} ){5})((?:[0-2]{5} ){5})\?\n/
      p "board: #{$2}"
      p "state: #{$3}"
      if $3.strip == BLANK_BOARD
        puts "~~~~~ RESETTING WORDS PLAYED ~~~~"
        WORDS_ALREADY_PLAYED.clear
      end
      words.each do |word|
        word = word.chomp
        if (move = can_play_word($2, word))
          p "sending back: #{move}"
          s.puts move
          break
        end
      end
  end

end

