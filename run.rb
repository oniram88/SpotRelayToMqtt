require 'spot'
require 'mqtt'
require 'logger'


SPOT.configure do |config|
  config.open_timeout = 30
  config.read_timeout = 80
end

sleep_time = ENV.fetch("SLEEP_TIME", 50).to_i
feed_id = ENV.fetch("FEED_ID") #0qqfzqKZH786qf8ktUWmbSSCm9DkuqZak
mqtt_uri = ENV.fetch("MQTT_URI", "mqtt://broker")
mqtt_topic = ENV.fetch("MQTT_TOPIC", "posizione_spot_gen")

raise "NO FEED_ID ENV setted" if feed_id.nil?
raise "NO MQTT_URI ENV setted" if mqtt_uri.nil?

api = SPOT::Client.new(feed_id: feed_id)
client = MQTT::Client.connect(mqtt_uri)

logger = Logger.new("posizione#{Time.now}.log")
ultimo = nil
first_run = true
puts "inizio Loop"
loop do
  puts Time.now
  begin

    messages_to_write = []

    if first_run
      first_run = false
      api.messages.all.each do |m|
        messages_to_write << m
      end
    else
      tmp = api.messages.latest
      if tmp
        if ultimo&.id != tmp&.id
          messages_to_write << tmp
        end
      end
    end

    unless messages_to_write.empty?
      messages_to_write.each do |m|
        puts "Scrivo #{m.id}"
        logger.info "ID:#{m.id} - #{m.latitude} - #{m.longitude}"
        client.publish(mqtt_topic, m.to_h.to_json, retain = false)
        ultimo = m
      end
    end

  rescue Exception => e
    puts e.message
  end
  sleep(sleep_time)
end
