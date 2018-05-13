class LinebotController < ApplicationController
  require 'line/bot'

  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text then
          message = {
            type: 'text',
            text: event.message['text']
          }
          client.reply_message(event['replyToken'], message)
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video then
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.binmode
          tf.write(response.body)
=begin          message = {
            type: "image",
            originalContentUrl: tf.path,
            previewImageUrl: tf.path
          }
=end
          message = {
            type: 'text',
            text: tf
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    }

    head :ok
  end
end