class HomeController < ApplicationController
  def index
    @msg = request.url
    @msg1 = request.path
  end
end
