require 'faraday'
require 'pry'
require 'nokogiri'
require "active_support/core_ext/object/try"
require "active_support/core_ext/object/blank"
require 'telegram/bot'
require 'logger'
require 'sequel'
require 'time'
require 'dotenv/load'

DB = Sequel.connect(adapter: :postgres, user: ENV["DB_USERNAME"], password: ENV["DB_PASSWORD"], host: 'localhost', port: 5432, database: ENV["DB_NAME"], max_connections: 10, logger: Logger.new('log/db.log'))

def request(url:)
  response = Faraday.get(url)
  response.body
end

Telegram.bots_config = {
  default: ENV["TELEGRAM_BOT_KEY"]
}

urls = DB[:urls]
loop do
  begin
    parsed_data = Nokogiri::HTML5(request(url: ARGV[0]))
    chats = Telegram.bot.get_updates["result"]
    parsed_data.css('.css-rc5s2u').reverse.each do |e|
      url_from_tag = e.attribute('href').value
      chats.each do |chat|
        if urls.where(url: url_from_tag).blank?
          p Time.now
          urls.insert(url: url_from_tag)
          Telegram.bot.send_message chat_id: 344658156, text: "#{e.css('.css-veheph.er34gjf0').text.split(' - ').try(:[], 1)} - https://www.olx.ua#{url_from_tag}"
        end
      end
    end
    sleep 30
  rescue
    p 'Error'
    Telegram.bot.send_message chat_id: 344658156, text: "There is an error, try to restart bot by /start"
  end
end
