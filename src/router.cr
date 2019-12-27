require "kemal"
require "json"

users = Hash(String, Hash(String, String)).new
sockets = Hash(String, HTTP::WebSocket).new

ws "/" do |socket|

  # Handle incoming message and dispatch it to all connected clients
  socket.on_message do |message|
    user = Hash(String, String).from_json(message)

    # Only add user if it does not already exist
    unless users.has_key?(user["username"])
      # Send all current users to the new connection
      socket.send users.to_json

      # Cache the current user
      user["pk"] = user["pk"]
      users[user["username"]] = user

      # Update the remaining connections with the new user information
      sockets.each_value do |a_socket|
        a_socket.send user.to_json
      end

      # Update the sockets hash
      sockets[user["username"]] = socket
    end
  end

  # Handle disconnection and update caches / connections
  socket.on_close do |_|
    # Remove socket reference
    username = sockets.key_for(socket)
    sockets.delete(username)

    # Remove user from user cache
    users.delete(username)

    # Notify all connections of the removed username
    sockets.each_value do |a_socket|
      a_socket.send username
    end

    puts "User #{username} disconnected. Closing Socket: #{socket}"
  end
end

Kemal.run

