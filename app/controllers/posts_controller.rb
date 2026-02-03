class PostsController < ApplicationController
  before_action :login_required, only: [ :create, :destroy ]

  before_action :set_posts, only: [ :index ]
  before_action :set_post, only: [ :destroy ]
  before_action :authorize_post!, only: [ :destroy ]

  def index
    render json: paginated_response
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
    @posts = Post.visible.includes(:user)
    @posts = filter_by_username
    @posts = @posts.where.not(video_url: nil) if params[:type] == "video"
  end

  def filter_by_username
    return @posts.feed_ordered_for(current_user) unless params[:username]

    user = User.find_by!(username: params[:username])
    @posts.where(user: user).order(id: :desc)
  end

  def offset
    params[:cursor].present? ? params[:cursor].to_i : 0
  end

  def limit
    [(params[:limit] || 10).to_i, 100].min
  end

  def paginated_response
    posts_array = @posts.to_a
    paginated = posts_array.drop(offset).take(limit)
    has_more = posts_array.size > offset + limit

    {
      posts: paginated.map { |post| post_payload(post) },
      nextCursor: has_more ? (offset + limit).to_s : nil
    }
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
