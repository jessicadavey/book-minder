require "sinatra"
require "sinatra/reloader" if development?
require "tilt/erubis"
require "date"
require "stamp"

configure do
  enable :sessions
  set :erb, :escape_html => true
  set :session_secret, 'secret'
end

before do
  session[:books] ||= []
  session[:error] ||= []
end

helpers do
  def format_date(date)
    date.stamp("January 1, 2020")
  end
end

def currently_reading(books)
  books.select do |book|
    book[:date_started] && !book[:date_completed]
  end
end

def have_read(books)
  books.select do |book|
    book[:date_started] && book[:date_completed]
  end
end

def to_read(books)
  books.select do |book|
    !book[:date_started] && !book[:date_completed]
  end
end

def next_id(books)
  return 0 if books.empty?
  books.map { |book| book[:id] }.max + 1
end

def parse_date(string)
  return nil unless string && string != ''
  year, month, day = string.split("-").map(&:to_i)
  Date.new(year, month, day)
end

def error_for_start_date(date)
  "Date started must be today's date or earlier." if date && date > Date.today
end

def error_for_complete_date(complete_date, start_date)
  return if complete_date.nil? || start_date.nil?
  if complete_date < start_date
    "Date completed must be after date started."
  elsif complete_date > Date.today
    "Date completed must be today's date or earlier."
  end
end

def error_for_title(title)
  if title == ""
    "You must enter a title."
  elsif !(1..70).cover?(title.size)
    "Title must be between 1 and 70 characters."
  end
end

def error_for_author(author)
  if author == ""
    "You must enter an author."
  elsif !(1..70).cover?(author.size)
    "Author's name must be between 1 and 70 characters."
  end
end

def check_errors(title, author, date_started, date_completed)
  session[:error] << error_for_start_date(date_started) if error_for_start_date(date_started)
  session[:error] << error_for_complete_date(date_completed, date_started) if error_for_complete_date(date_completed, date_started)
  session[:error] << error_for_title(title) if error_for_title(title)
  session[:error] << error_for_author(author) if error_for_author(author)
end

# Load the home page
get "/" do
  @currently_reading = currently_reading(session[:books])
  @books_read = have_read(session[:books])
  @books_to_read = to_read(session[:books])
  erb :index
end

# View the add a book form
get "/add" do
  erb :add
end

# Add a book
post "/add" do
  id = next_id(session[:books])

  date_started = parse_date(params["date_started"])
  date_completed = parse_date(params["date_completed"])
  title = params["title"].strip
  author = params["author"].strip

  check_errors(title, author, date_started, date_completed)

  if !session[:error].empty?
    erb :add
  else
    session[:books] << {
      id: id,
      title: title,
      author: author,
      date_started: date_started,
      date_completed: date_completed
    }

    session[:success] = "'#{params["title"]}' successfully added."
    redirect "/"
  end
end

# View the edit a book page
get "/edit/:id" do
  @book = session[:books].find do |book|
    book[:id] == params[:id].to_i
  end
  erb :edit
end

# Edit a book
post "/edit/:id" do

  date_started = parse_date(params["date_started"])
  date_completed = parse_date(params["date_completed"])
  title = params["title"].strip
  author = params["author"].strip

  check_errors(title, author, date_started, date_completed)

  @book = session[:books].find do |book|
    book[:id] == params[:id].to_i
  end

  if !session[:error].empty?
    erb :edit
  else
    @book[:title] = title
    @book[:author] = author
    @book[:date_started] = date_started
    @book[:date_completed] = date_completed
    session[:success] = "'#{params["title"]}' has been updated."
    redirect "/"
  end
end

# Delete a book
post "/delete/:id" do
  current_book = session[:books].find do |book|
    book[:id] == params[:id].to_i
  end
  title = current_book[:title]
  session[:books].reject! do |book|
    book[:id] == params[:id].to_i
  end
  session[:success] = "'#{title}' has been deleted."
  redirect "/"
end

# Start reading a book
post '/start/:id' do
  current_book = session[:books].find do |book|
    book[:id] == params[:id].to_i
  end

  current_book[:date_started] = Date.today
  title = current_book[:title]
  session[:success] = "'#{title}' started today."
  redirect "/"
end

# Finish reading a book
post '/finish/:id' do
  current_book = session[:books].find do |book|
    book[:id] == params[:id].to_i
  end

  current_book[:date_completed] = Date.today
  title = current_book[:title]
  session[:success] = "'#{title}' completed today."
  redirect "/"
end
