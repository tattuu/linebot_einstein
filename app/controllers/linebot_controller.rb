class LinebotController < ApplicationController

  require 'jwt'
  require 'rest-client'
  require 'json'

  require 'line/bot'

  protect_from_forgery :except => [:callback]

  msg6 = ""

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
          tf.open
          File.open("#{Rails.root}/public/images/store.jpg","wb") do |file|
  #            File.chmod(0777, "#{Rails.root}/public/images/store.jpg")
              file.write(tf.read)
              file.close
          end

          redirect_to :action => 'auth'

          message = {
              type: 'text',
              text: msg6
          }
          client.reply_message(event['replyToken'], message)

=begin
          message = {
              type: "image",
              originalContentUrl: "https://really-linebot.herokuapp.com/images/store.jpg",
              previewImageUrl: "https://really-linebot.herokuapp.com/images/store.jpg"
          }
          client.reply_message(event['replyToken'], message)
=end
          end
      end
      }
      head :ok
  end

  def auth
      ps_endpoint = ENV['EINSTEIN_VISION_URL']
      subject = ENV['EINSTEIN_VISION_ACCOUNT_ID']
      model_id = ENV['CUSTOM_MODEL_ID']
      private_key = String.new(ENV['EINSTEIN_VISION_PRIVATE_KEY'])

      private_key.gsub!('\n', "\n")
      expiry = Time.now.to_i + (60 * 15)

      # Read the private key string as Ruby RSA private key
      rsa_private = OpenSSL::PKey::RSA.new(private_key)

      # Build the JWT payload
      payload = {
              :sub => subject,
              :aud => "https://api.einstein.ai/v2/oauth2/token",
              :exp => expiry
          }

      # Sign the JWT payload
      assertion = JWT.encode payload, rsa_private, 'RS256'
      @msg1 = ps_endpoint + 'v2/oauth2/token'
      # Call the OAuth endpoint to generate a token
      response = RestClient.post(ps_endpoint + 'v2/oauth2/token', {
              grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
              assertion: assertion
          })

      token_json = JSON.parse(response)
      @msg2 = "\nGenerated access token:\n"
      @msg3 = JSON.pretty_generate(token_json)

      access_token = token_json["access_token"]

      response = JSON.parse(
          RestClient.post('https://api.metamind.io/v1/vision/predict',
                  {:sampleLocation => "https://really-linebot.herokuapp.com/images/store.jpg",
                   :modelId => model_id, :multipart => true},
                  headers = {:authorization=> "Bearer #{access_token}"}))
      msg6 = JSON.pretty_generate(response)
  end
end
