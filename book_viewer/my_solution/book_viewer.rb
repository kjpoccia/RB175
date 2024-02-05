require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"

helpers do
  def in_paragraphs(text)
    text.split("\n\n").join("</p><p>").prepend("<p>")
  end

  def find_text(query)
    return nil if query == ""
    results = []
    @toc.each_with_index do |title, idx|
      temp = File.read "data/chp#{idx + 1}.txt"
      results << (idx + 1) if temp.match(query)
    end
    return nil if results.empty?
    results
  end
end

before do
  @toc = File.readlines("data/toc.txt")
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  erb :home
end

get "/chapters/:number" do
  @number = params[:number].to_i
  redirect "/" unless (1..@toc.size).cover?(@number)

  @chapter_title = @toc[@number - 1]
  @chapter = File.read "data/chp#{@number}.txt"
  erb :chapter
end

get "/search" do
  erb :search
end

not_found do
  redirect "/"
end