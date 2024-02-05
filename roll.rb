require "socket"

server = TCPServer.new("localhost", 3003)

loop do
  client = server.accept

  request_line = client.gets
  next if !request_line || request_line =~ /favicon/
  puts request_line

  http_method = request_line[0, 3]
  path = request_line[4..request_line.index("?") - 1]
  rolls = request_line.index("rolls=") + 6
  sides = request_line.index("sides=") + 6
  params = { "rolls" => request_line[rolls], "sides" => request_line[sides] }


  client.puts "HTTP/1.1 200 OK"
  client.puts "Content-Type: text/plain\r\n\r\n"
  client.puts request_line

  params["rolls"].to_i.times { client.puts rand(params["sides"].to_i) + 1 }

  client.close
end