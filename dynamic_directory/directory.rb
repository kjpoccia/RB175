require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"

get "/" do
  @files = Dir.glob("*", base: "public", sort: true )
  @files.reverse! if params[:sort] == "desc"
  erb :list
end

