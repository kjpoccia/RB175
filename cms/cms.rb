require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"
require "redcarpet"
require "yaml"
require "bcrypt"

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

before do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
end

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

def name_error(name)
  if @files.include?(name)
    "File name must be unique"
  elsif name.empty?
    "Please enter a file name"
  end
end

def correct_credentials?(user, password)
  credentials = load_user_credentials

  if credentials.key?(user)
    bcrypt_password = BCrypt::Password.new(credentials[user])
    bcrypt_password == password
  else
    false
  end
end

def require_signed_in_user
  unless session[:signed_in]
    session[:alert] = "You need to be signed in to make changes."
    redirect "/"
  end
end

get "/" do
  erb :files
end

get "/new" do
  require_signed_in_user

  erb :new_file
end

get "/sign_in" do
  erb :sign_in
end

get "/:file_name" do
  @file_name = params[:file_name]
  @file_path = File.join(data_path, @file_name)
  if @files.include?("#{@file_name}")
    load_file_content(@file_path)
  else
    session[:alert] = "#{@file_name} does not exist"
    redirect "/"
  end
end

get "/:file_name/edit" do
  require_signed_in_user

  @file_name = params[:file_name]
  @file_path = File.join(data_path, @file_name)
  @content = File.read(@file_path)
  erb :edit_file
end

post "/:file_name/delete" do
  require_signed_in_user

  @file_name = params[:file_name]
  @file_path = File.join(data_path, @file_name)
  File.delete(@file_path)
  session[:alert] = "#{@file_name} has been deleted."
  redirect "/"
end

post "/:file_name/edit" do
  require_signed_in_user

  @file_name = params[:file_name]
  @file_path = File.join(data_path, @file_name)
  File.write(@file_path, params[:file_content])
  session[:alert] = "#{@file_name} has been updated."
  redirect "/"
end

post "/new" do
  require_signed_in_user

  @file_name = "#{params[:file_name].strip}"

  if name_error(@file_name)
    session[:alert] = name_error(@file_name)
    status 422
    erb :new_file
  else
    @file_path = File.join(data_path, @file_name)
    File.write(@file_path, "")
    
    session[:alert] = "#{@file_name} has been created."
    redirect "/"
  end
end

post "/sign_in" do
  @user_name = params[:user_name]
  @password = params[:password]
  if correct_credentials?(@user_name, @password)
    session[:signed_in] = true
    session[:alert] = "Welcome!"
    redirect "/"
  else
    status 422
    session[:alert] = "Invalid credentials"
    erb :sign_in
  end
end

post "/sign_out" do
  session[:signed_in] = false
  session[:alert] = "You have been signed out."
  redirect "/"
end












