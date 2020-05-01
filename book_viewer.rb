require 'tilt/erubis'
require "sinatra"
# application reloads files every time a page is loaded, very nice apparently?
# production? and development? are Sinatra methods that check RACK_ENV environment variables
# heroku sets the var to automatically to production
require "sinatra/reloader" if development?

# filter
# defined for every path
before do
  @contents = File.readlines "data/toc.txt"
end

# methods made available in templates are put here
helpers do
  def in_paragraphs(text)
    text.split("\n\n").map.with_index do |paragraph, index|
      "<p id=paragraph#{index}>#{paragraph}</p>"
    end.join
  end

  def highlight(text, term)
    text.gsub(term, "<strong>#{term}</strong>")
  end
end

# when path is /, read template file and send returned string to browser when GET
get "/" do
  @title = "The Adventures of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number].to_i
  chapter_name = @contents[number - 1]
  
  redirect "/" unless (1..@contents.size).cover? number
  
  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read "data/chp#{number}.txt"

  erb :chapter
end

#define function for search here
def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def chapters_matching(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |number, name, contents|
    matches = paragraphs_matching(contents, query)
    results << { number: number, name: name , paragraphs: matches} unless matches.empty?
  end

  results
end

def paragraphs_matching(text, query)
  paragraphs = {}

  text.split("\n\n").each_with_index do |paragraph, index|
    paragraphs[index] = paragraph if paragraph.include?(query)
  end

  paragraphs
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect "/"
end