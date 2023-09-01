# frozen_string_literal: true

# controller action for Users
class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def show
    @user = current_user
  end
end
