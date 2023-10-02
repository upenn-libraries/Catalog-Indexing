# frozen_string_literal: true

# controller action for Users
class UsersController < ApplicationController
  def index
    @users = User.page(params[:page])
    @users = @users.filter_active(params.dig('filter', 'active_status')) if params.dig('filter', 'active_status').present?
  end

  def show
    @user = User.find params[:id]
  end
end
