class UsernameSeatsController < ApplicationController
  def show
    username = params[:username].to_s.strip.downcase

    unless valid_username?(username)
      head :bad_request
      return
    end

    if User.exists?(username: username)
      head :conflict
      return
    end

    head :ok
  end

private

  def valid_username?(username)
    return false if username.blank?
    return false if username.length < 3 || username.length > 100
    return false unless username.match?(/\A[a-z][a-z0-9]*\z/)

    true
  end
end
