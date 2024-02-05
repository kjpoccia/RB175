require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

configure do
  set :erb, :escape_html => true
end

helpers do
  def all_done?(list)
    complete = (list[:todos].all? do |todo|
      todo[:completed] == true
    end)
    complete && list[:todos].size > 0
  end

  def count_incomplete(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end

  def list_class(list)
    "complete" if all_done?(list)
  end

  def sort_lists(lists, &block)
    incomplete_lists = []
    complete_lists = []

    lists.each do |list|
      if all_done?(list)
        complete_lists << list
      else
        incomplete_lists << list
      end
    end

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    incomplete_todos = []
    complete_todos = []

    todos.each do |todo|
      if todo[:completed]
        complete_todos << todo
      else
        incomplete_todos << todo
      end
    end

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

before do
  session[:lists] ||= []
end

def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters."
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique."
  end
end

def error_for_todo(todo)
  if !(1..100).cover? todo.size
    "Todo must be between 1 and 100 characters."
  end
end

def load_list(index)
  list = session[:lists].select { |list| list[:index] == index.to_i }[0]
  return list if list

  session[:error] = "This list does not exist."
  redirect "/lists"
end

def load_todo(list, id)
  list[:todos].select { |todo| todo[:id] == id.to_i }[0]
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list
end

def next_list_id
  max = session[:lists].map { |list| list[:index] }.max || 0
  max + 1
end

# Create a new list
post "/lists" do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    index = next_list_id
    session[:lists] << { index: index, name: list_name, todos: [] }
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# View a single list
get "/lists/:index" do
  @index = params[:index]
  @list = load_list(@index)
  erb :list_viewer
end

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

# Add todos to a list
post "/lists/:index" do
  text = params[:todo].strip
  todo_error = error_for_todo(text)
  @index = params[:index].to_i
  @list = load_list(@index)

  if todo_error
    session[:error] = todo_error
    erb :list_viewer
  else
    id = next_todo_id(@list[:todos])
    @list[:todos] << { id: id, name: text, completed: false }

    session[:success] = "The todo was added."
    redirect "/lists/#{@index}"
  end
end

# Edit an existing todo list
get "/lists/:index/edit" do
  @index = params[:index].to_i
  @list = load_list(@index)
  erb :edit_list
end

# Update an existing todo list
post "/lists/:index/edit" do
  @index = params[:index]
  @list = load_list(@index)

  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    redirect "/lists/#{@index}/edit"
  else
    @list[:name] = params[:list_name]
    session[:success] = "List name has been updated."
    redirect "/lists/#{@index}"
  end
end

# Delete a list
post "/lists/:index/delete" do
  @index = params[:index]
  @list = load_list(@index)
  session[:lists].delete(@list)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list has been deleted."
    redirect "/lists"
  end
end

# Delete a todo
post "/lists/:index/delete/:id" do
  @index = params[:index]
  @list = load_list(@index)
  @todo = load_todo(@list, params[:id])
  @list[:todos].delete(@todo)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo has been deleted."
    redirect "/lists/#{@index}"
  end
end

# Check or uncheck a todo
post "/lists/:index/complete/:id" do
  @index = params[:index]
  @list = load_list(@index)
  @todo = load_todo(@list, params[:id])
  is_completed = params[:completed] == "true"
  @todo[:completed] = is_completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@index}"
end

# Mark all todos as complete in a list
post "/lists/:index/complete" do
  @index = params[:index]
  @list = load_list(@index)
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos have been completed."
  redirect "/lists/#{@index}"
end















