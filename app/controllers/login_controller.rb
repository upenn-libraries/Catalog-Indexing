# frozen_string_literal: true

# handles requests from user login entrypoint
class LoginController < ApplicationController
  skip_before_action :authenticate_user!, only: :index

  def index; end
end
