# frozen_string_literal: true

# controller action for Users
class UsersController < ApplicationController
  before_action :authenticate_user!
  def index
    @users = User.all
  end

  def show
    @user = current_user
  end
end
