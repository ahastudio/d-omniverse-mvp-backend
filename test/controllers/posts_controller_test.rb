require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "GET /posts" do
    get posts_url, as: :json

    assert_response :ok

    assert_match posts(:text_only_update).id, response.body
    assert_match posts(:text_only_update).content, response.body
  end

  test "GET /posts?type=video" do
    get posts_url(type: "video"), as: :json

    assert_response :ok

    assert_match posts(:admin_update).id, response.body
    refute_match posts(:text_only_update).id, response.body
  end

  test "POST /posts" do
    user = users(:admin)
    token = user.generate_token

    post posts_url,
         params: { content: "New post content" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    assert_match "New post content", response.body
  end

  test "POST /posts - with video URL" do
    user = users(:dancer)
    token = user.generate_token

    post posts_url,
         params: {
           content: "Video post",
           videoUrl: "https://example.com/video.mp4"
         },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    assert_match "Video post", response.body
    assert_match "https://example.com/video.mp4", response.body
  end

  test "POST /posts - duplicate within 10 seconds" do
    user = users(:admin)
    token = user.generate_token

    post posts_url,
         params: { content: "Duplicate test" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    post posts_url,
         params: { content: "Duplicate test" },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :unprocessable_entity
    assert_match "Duplicate post detected", response.body
  end

  test "POST /posts - with video" do
    user = users(:dancer)
    token = user.generate_token

    video_data = File.binread(file_fixture("sample.mp4"))
    base64_data = Base64.strict_encode64(video_data)
    data_url = "data:video/mp4;base64,#{base64_data}"

    path = "/videos/hls/TESTKEY/playlist.m3u8"
    original_process_video = Post.instance_method(:process_video)
    Post.define_method(:process_video) { self.video_url = path }

    post posts_url,
         params: {
           content: "Video with base64",
           videoUrl: data_url
         },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    assert_match "Video with base64", response.body
    assert_match "/videos/hls/TESTKEY/playlist.m3u8", response.body
    refute_match "data:", response.body
  ensure
    Post.define_method(:process_video, original_process_video)
  end

  test "DELETE /posts/:id" do
    user = users(:admin)
    token = user.generate_token
    post = posts(:text_only_update)

    delete post_url(post),
           headers: { "Authorization": "Bearer #{token}" },
           as: :json

    assert_response :no_content

    assert_not_nil post.reload.deleted_at
  end

  test "DELETE /posts/:id - forbidden" do
    user = users(:dancer)
    token = user.generate_token
    post = posts(:text_only_update)

    delete post_url(post),
           headers: { "Authorization": "Bearer #{token}" },
           as: :json

    assert_response :forbidden
  end

  test "DELETE /posts/:id - unauthorized" do
    post = posts(:text_only_update)

    delete post_url(post), as: :json

    assert_response :unauthorized
  end

  test "GET /posts - authenticated user - recommended order" do
    user = users(:admin)
    token = user.generate_token

    get posts_url,
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :ok

    data = JSON.parse(response.body)

    # 전체 피드 확인
    assert_operator data.length, :>, 0, "피드에 게시물이 있어야 함"

    # 게시물 정보 추출
    feed = data.map do |post|
      {
        id: post["id"],
        author: post["user"]["username"],
        is_self: post["user"]["id"] == user.id
      }
    end

    # 1. 본인 최신 글이 최상단인지 확인
    assert feed[0][:is_self], "첫 번째 게시물은 본인 글이어야 함"
    assert_equal posts(:admin_update).id, feed[0][:id],
                 "본인 최신 게시물(admin_update, id=002)이 최상단"

    # 2. 작성자 다양성: 같은 작성자 3번 이상 연속 금지
    consecutive_count = 1
    max_consecutive = 1
    user_ids = data.map { |p| p["user"]["id"] }

    user_ids.each_cons(2) do |prev, curr|
      if prev == curr
        consecutive_count += 1
        max_consecutive = [ max_consecutive, consecutive_count ].max
      else
        consecutive_count = 1
      end
    end

    assert max_consecutive <= 2,
           "같은 작성자 3번 이상 연속 금지 (현재: #{max_consecutive}번)"

    # 3. dancer(5점)가 creator(3점)보다 대체로 앞에
    any_dancer_idx = feed.index { |p| p[:author] == "dancer" }
    any_creator_idx = feed.index { |p| p[:author] == "creator" }

    assert any_dancer_idx < any_creator_idx,
           "dancer(5점) < creator(3점): idx #{any_dancer_idx} < #{any_creator_idx}"
  end

  test "GET /posts - feed algorithm verification" do
    user = users(:admin)
    token = user.generate_token

    get posts_url,
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :ok

    data = JSON.parse(response.body)

    # 본인 최신 글이 최상단
    assert_equal user.id, data[0]["user"]["id"], "본인 최신 글 최상단"
    assert_equal posts(:admin_update).id, data[0]["id"]

    # 작성자 다양성: 같은 작성자 3번 이상 연속으로 나오면 안 됨
    consecutive_count = 1
    max_consecutive = 1

    data.map { |p| p["user"]["id"] }.each_cons(2) do |prev, curr|
      if prev == curr
        consecutive_count += 1
        max_consecutive = [ max_consecutive, consecutive_count ].max
      else
        consecutive_count = 1
      end
    end

    assert max_consecutive <= 2,
           "같은 작성자 3번 이상 연속 금지 (현재: #{max_consecutive}번)"
  end

  test "GET /posts - friend of friend boost" do
    # dancer 입장에서 테스트
    # dancer → creator 관계(10) 있음
    # admin은 dancer와 직접 관계 없음
    # 하지만 admin → dancer(5) 있으므로 dancer 입장에서 admin은 "친구의 친구"
    user = users(:dancer)
    token = user.generate_token

    get posts_url,
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :ok

    data = JSON.parse(response.body)
    post_ids = data.map { |post| post["id"] }

    # 같은 rank(1)의 게시물 비교: creator_post2 vs admin_update
    # dancer → creator: 10점 직접 관계
    # admin → dancer: 5점 역방향 → admin 글에 1.5점 부스트
    creator_post2_index = post_ids.index(posts(:creator_post2).id)
    admin_update_index = post_ids.index(posts(:admin_update).id)

    assert creator_post2_index < admin_update_index,
           "직접 관계(10점)가 역방향 관계(1.5점)보다 앞에 와야 함"
  end
end
