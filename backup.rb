require 'rubygems'
require 'mechanize'

puts "=> BackUp for blog.tyden.cz"

@images = []

def parse_article detail
  text = detail.parser.at_css("textarea#text").inner_html
  parsed_img = detail.parser.at_css("textarea#text img")
  img = parsed_img[:src] || nil if parsed_img

  data = {}
  detail.form_with(:action => './admin-polozka-ulozit.php') do |f|
    data[:id_clanky] = f.id_clanky
    data[:date_vydani] = f.date_vydani
    data[:nadpis] = f.nadpis
    data[:text] = text
    data[:active_state] = f.active_state
    data[:koment] = f.koment
    data[:hodnoceni] = f.hodnoceni
    data[:img] = img
  end
  @images << "http://blog.tyden.cz#{img}" if img
  data
end

def parse_first articles_page
  articles = []
  articles_page.links.each do |l|
    articles << parse_article(l.click) if l.text == "Edit"
  end
  puts "=> Create file 'parsed_articles_1.txt'"
  File.open("parsed_articles_1.txt", 'w') do |file|
    file.write(articles)
  end
end

def parse_others articles_page, page
  puts "=> Parsing #{page}. page of articles"
  articles = []
  articles_page.links.each do |l|
    articles << parse_article(l.click) if l.text == "Edit"
  end
  puts "=> Create file 'parsed_articles_#{page}.txt'"
  File.open("parsed_articles_#{page}.txt", 'w') do |file|
    file.write(articles)
  end
end


a = Mechanize.new
a.get('http://blog.tyden.cz/admin/') do |page|
  puts "=> Starting BackUp at #{Time.now}"
  # Login to blog.tyden.cz
  my_page = page.form_with(:action => './admin-login.php') do |f|
    f.login = ARGV[0]
    f.password = ARGV[1]
  end.click_button

  # Get articles list
  if articles = my_page.link_with(:href => "admin-clanky-vypis.php")
    puts "=> Successfully logged in as #{ARGV[0]}"
    articles_page = articles.click
    puts "=> Going to articles overview page"
  else
    puts "=> You are not logged in !!!!"
  end

  puts "=> Parsing 1. page of articles"
  parse_first(articles_page)

  articles_page.links.each do |l| 
    parse_others(l.click, l.text) if /^[1-9]+$/.match(l.text)
  end

  puts "=> Create file 'parsed_images.txt'"
  File.open("parsed_images.txt", 'w') do |file|
    file.write(@images.join("\n"))
  end

  puts "=> BackUp Complete at #{Time.now}"
end

