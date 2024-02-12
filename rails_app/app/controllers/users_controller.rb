# frozen_string_literal: true

# controller action for Users
class UsersController < ApplicationController
  before_action :load_user, only: %w[show edit update]

  def index
    @users = User.page(params[:page])
    @users = @users.filter_status(params.dig('filter', 'status')) if params.dig('filter', 'status').present?
  end

  def show; end

  def new
    @user = User.new
  end

  def create
    @user = User.new user_params.merge(provider: 'saml')
    if @user.save
      flash.notice = "User access granted for #{@user.uid}"
      redirect_to user_path(@user)
    else
      flash.alert = "Problem adding user: #{@user.errors.map(&:full_message).join(', ')}"
      render :edit
    end
  end

  def edit; end

  def update
    @user.update user_params
    if @user.save
      flash.notice = 'User updated'
      redirect_to user_path(@user)
    else
      flash.alert = "Problem updating user: #{@user.errors.map(&:full_message).join(', ')}"
      render :edit
    end
  end

  private

  # @return [User]
  def load_user
    @user = User.find params[:id]
  end

  def user_params
    params.require(:user).permit(:uid, :email, :active)
  end
end
