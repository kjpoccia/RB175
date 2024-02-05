require "tilt/erubis"
require "sinatra"
require "sinatra/reloader" if development?

helpers do
  def in_paragraphs_ids(text)
    paragraphs = text.split("\n\n")
    paragraphs.each_with_index do |para, idx|
      para.prepend("<p id=\"paragraph-#{idx}\">").concat("</p>")
    end

    paragraphs.join
  end

  def return_paragraph(number, idx)
    text = File.read "data/chp#{number}.txt"
    paragraphs = text.split("\n\n")
    paragraphs[idx]
  end

  def bold_it(paragraph, query)
    paragraph.sub(query, "<strong>#{query}</strong>")
  end
end

def each_chapter
  @toc.each_with_index do |title, idx|
    number = idx + 1
    contents = File.read ("data/chp#{number}.txt")
    yield title, number, contents
  end
end

def matches(query)
  results = []
  
  return results if !query || query.empty?

  each_chapter do |title, number, contents|
    results << { number: number, title: title } if contents.include?(query)
  end

  paragraphs_matching(results, query)
end

def paragraphs_matching(results, query)
  results.each_with_index do |chapter, idx|
    contents = in_paragraphs_ids(File.read ("data/chp#{results[idx][:number]}.txt")).split("</p>")
    results[idx][:paragraphs] = []
    contents.each_with_index do |paragraph, id|
      results[idx][:paragraphs] << id if paragraph.include?(query)
    end
  end
  results
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
  @results = matches(params[:query])
  erb :search
end

not_found do
  redirect "/"
end