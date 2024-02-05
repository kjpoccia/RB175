require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"
require 'yaml'



helpers do
  def count_users
    @users.size
  end

  def count_interests
    total = 0
    @users.each do |user|
      total += @user_data[user][:interests].size
    end
    total
  end
end

before do
  @user_data = YAML.load_file("data/users.yml")
  @users = @user_data.keys
end

get "/" do
  redirect "/users"
end

get "/users" do
  erb :users_list
end

get "/users/:name" do
  @name = params[:name].to_sym
  redirect "/users" unless @users.include?(@name)

  @email = @user_data[@name][:email]
  @interests = @user_data[@name][:interests]
  erb :profile
end