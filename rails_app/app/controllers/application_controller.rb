# frozen_string_literal: true

# parent controller
class ApplicationController < ActionController::Base
  before_action :authenticate_user!
end
