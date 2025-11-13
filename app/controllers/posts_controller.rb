class PostsController < ApplicationController
  before_action :set_posts, only: [ :index ]

  def index
    render json: posts_payload,
           status: :ok
  end

  private

  def set_posts
    @posts = Post.includes(:user).order(id: :desc)
  end

  def posts_payload
    @posts.map do |post|
      {
        id: post.id,
        user: {
          id: post.user.id,
          username: post.user.username,
          nickname: post.user.nickname,
          avatarUrl: post.user.avatar_url
        },
        content: post.content,
        videoUrl: post.video_url,
        createdAt: post.created_at&.iso8601,
        updatedAt: post.updated_at&.iso8601
      }
    end
  end
end
