# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pagy::Method
  include Authenticatable
end
