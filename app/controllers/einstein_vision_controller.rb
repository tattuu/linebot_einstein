class EinsteinVisionController < ApplicationController

    require 'jwt'
    require 'rest-client'
    require 'json'

    def auth

        ps_endpoint = ENV['EINSTEIN_VISION_URL']
        subject = ENV['EINSTEIN_VISION_ACCOUNT_ID']
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
=begin        # Call the OAuth endpoint to generate a token
        response = RestClient.post(ps_endpoint + 'v2/oauth2/token', {
                grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                assertion: assertion
            })

        token_json = JSON.parse(response)
        @msg1 = "\nGenerated access token:\n"
        @msg2 = JSON.pretty_generate(token_json)

        access_token = token_json["access_token"]
        @msg3 = access_token
=end
    end
end
