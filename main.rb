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

Dotenv.load("#{__dir__}/.env")
DB = Sequel.connect(adapter: :postgres, user: ENV["DB_USERNAME"], password: ENV["DB_PASSWORD"], host: 'localhost', port: 5432, database: ENV["DB_NAME"], max_connections: 10)

def request(url:)
  response = Faraday.get(url)
  response.body
end

DB.create_table? :urls do
  primary_key :id
  column :url, String, unique: true
end

Telegram.bots_config = {
  default: ENV["TELEGRAM_BOT_KEY"]
}

app_logger = Logger.new("#{__dir__}/log/app.log")

urls = DB[:urls]
loop do
  begin
    parsed_data = Nokogiri::HTML5(request(url: ARGV[0]))
    chats = Telegram.bot.get_updates["result"]
    parsed_data.css('.css-rc5s2u').reverse.each do |e|
      url_from_tag = e.attribute('href').value
      if urls.where(url: url_from_tag).blank?
        app_logger.info "There is new flat #{Time.now} #{url_from_tag}"
        urls.insert(url: url_from_tag)
        chats.map { |e| e.dig("message", "chat", "id") }&.uniq.each do |chat|
          Telegram.bot.send_message chat_id: chat, text: "#{e.css('.css-veheph.er34gjf0').text.split(' - ').try(:[], 1)} - https://www.olx.ua#{url_from_tag}"
        end
      end
    end
    sleep 30
  rescue => e
    app_logger.fatal "Error #{e}"
  end
end
