class PostsController < ApplicationController
  before_action :login_required, only: [ :create ]

  before_action :set_posts, only: [ :index ]

  def index
    render json: posts_payload,
           status: :ok
  end

  def create
    @post = current_user.posts.new(post_params)
    @post.id = ULID.generate
    @post.save!

    render json: post_payload(@post),
           status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages },
           status: :unprocessable_entity
  end

  private

  def set_posts
    @posts = Post.includes(:user).order(id: :desc)
    @posts = @posts.where.not(video_url: nil) if params[:type] == "video"
  end

  def posts_payload
    @posts.map { |post| post_payload(post) }
  end

  def post_payload(post)
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

  def post_params
    params.permit(:content, :videoUrl)
      .transform_keys(&:underscore)
  end
end
