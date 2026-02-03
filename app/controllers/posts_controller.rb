class PostsController < ApplicationController
  before_action :login_required, only: [ :create, :destroy ]

  before_action :set_posts, only: [ :index ]
  before_action :set_post, only: [ :destroy ]
  before_action :authorize_post!, only: [ :destroy ]

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

  def destroy
    @post.destroy!

    head :no_content
  end

private

  def set_post
    @post = Post.find(params[:id])
  end

  def authorize_post!
    return if @post.user_id == current_user.id

    render json: { error: "Forbidden" }, status: :forbidden
  end

  def set_posts
    @posts = Post.visible.includes(:user).feed_ordered_for(current_user)
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
