#Include sql
using SQLite

include("shogi.jl")
#print("starting")
#Checks if filename is included
if length(ARGS) != 1
  print_with_color(:red, "ERROR: Filename required to initialize board. \n")
  exit(1)
end

filename = ARGS[1]
#Opens the database
db = SQLite.DB(filename)
#print(".")
#Boolean value for standard/mini

#fetch
gamemode = SQLite.query(db, "SELECT value FROM meta WHERE key = 'type'")[1].values[1]
println("$gamemode")
tic()

game = startGame(gamemode)


#print(game.board)
moves = SQLite.query(db, "SELECT * FROM moves")
update(game, moves)
#start the timer


#println(".")
#printBoard(game)
#start find who you are playing as
num = length(moves[:move_number])
player = num % 2 == 1 ? "w" : "b"
other = player == "w" ? "b" : "w"

#pick a randomish move
#seed the RNGeesuz
seed = SQLite.query(db, "SELECT value FROM meta WHERE key = 'seed'")[1].values[1]
seed = parse(Int, seed)
srand(seed)
for i in 1:num
  rand()
end

s = ai(game, player)

#timing
time = toq()
println("Time taken is $time seconds")
time = round(Int, time)
timed = SQLite.query(db, "SELECT value FROM meta WHERE key = 'timed'")[1].values[1]
if timed == "yes"
  time_add = SQLite.query(db, "SELECT value FROM meta WHERE key = 'time_add'")[1].values[1]
  time_add = parse(Int, time_add)
  a = player == "w" ? "gote_time" : "sente_time"
  #print(a)
  time_left = SQLite.query(db, "SELECT value FROM meta WHERE key = '$a'")[1].values[1]
  time_left = parse(Int, time_left)
  time_left += time_add
  time_left -= time
  SQLite.query(db, "UPDATE meta SET value = '$time_left' WHERE key = '$a'")
  if time < 0
    SQLite.query(db, "INSERT INTO moves(move_number, move_type) VALUES ($(num+1), 'resign')")
    exit(1)
  end
end

if s == "resign"
  SQLite.query(db, "INSERT INTO moves(move_number, move_type) VALUES ($(num+1), 'resign')")
  exit(1)
end

if typeof(s.move) == move
  sx = s.move.sourcex
  sy = s.move.sourcey
  tx = s.move.location.column
  ty = s.move.location.row
  tx2 = s.move.location.column2
  ty2 = s.move.location.row2
  promote = s.move.promote ? "'!'" : "NULL"
  if tx2 == 0
    SQLite.query(db, "INSERT INTO moves(move_number, move_type, sourcex, sourcey, targetx, targety, option)
                    VALUES ($(num+1), 'move', $sx, $sy, $tx, $ty, $promote)")
  else
    SQLite.query(db, "INSERT INTO moves(move_number, move_type, sourcex, sourcey, targetx, targety, option, targetx2, targety2)
                    VALUES ($(num+1), 'move', $sx, $sy, $tx, $ty,  $promote, $tx2, $ty2)")
  end

elseif typeof(s.move) == drop
  tx = s.move.targetx
  ty = s.move.targety
  p = s.move.piece
  #println(p)
  SQLite.query(db, "INSERT INTO moves(move_number, move_type, targetx, targety, option) VALUES($(num+1), 'drop', $tx, $ty, '$p')")
end
