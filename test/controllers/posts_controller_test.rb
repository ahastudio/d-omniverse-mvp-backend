require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "GET /posts - response format" do
    get posts_url, as: :json

    assert_response :ok

    data = JSON.parse(response.body)

    # 새로운 응답 형식 확인
    assert data.key?("posts"), "posts 키가 있어야 함"
    assert data.key?("nextCursor"), "nextCursor 키가 있어야 함"

    # posts 배열에 게시물 포함
    post_ids = data["posts"].map { |p| p["id"] }
    assert_includes post_ids, posts(:text_only_update).id
  end

  test "GET /posts?type=video" do
    get posts_url(type: "video"), as: :json

    assert_response :ok

    data = JSON.parse(response.body)
    post_ids = data["posts"].map { |p| p["id"] }

    assert_includes post_ids, posts(:admin_update).id
    refute_includes post_ids, posts(:text_only_update).id
  end

  test "GET /posts - pagination with limit" do
    get posts_url(limit: 3), as: :json

    assert_response :ok

    data = JSON.parse(response.body)

    assert_equal 3, data["posts"].length, "limit=3이면 3개 반환"
    assert_not_nil data["nextCursor"], "더 있으면 nextCursor 존재"
  end

  test "GET /posts - pagination with cursor" do
    # 첫 페이지
    get posts_url(limit: 2), as: :json
    first_page = JSON.parse(response.body)
    first_page_ids = first_page["posts"].map { |p| p["id"] }
    cursor = first_page["nextCursor"]

    # 두 번째 페이지
    get posts_url(limit: 2, cursor: cursor), as: :json
    second_page = JSON.parse(response.body)
    second_page_ids = second_page["posts"].map { |p| p["id"] }

    # 중복 없어야 함
    assert_empty(first_page_ids & second_page_ids, "페이지 간 중복 없어야 함")
  end

  test "GET /posts - last page has no cursor" do
    # 매우 큰 limit으로 전체 가져오기
    get posts_url(limit: 1000), as: :json

    data = JSON.parse(response.body)

    assert_nil data["nextCursor"], "마지막 페이지면 nextCursor=null"
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

  test "POST /posts - with parentId" do
    user = users(:admin)
    token = user.generate_token
    parent = posts(:parent_post)

    post posts_url,
         params: {
           content: "Reply content",
           parentId: parent.id
         },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :created

    json = JSON.parse(response.body)
    assert_equal parent.id, json["parentId"]
  end

  test "POST /posts - with invalid parentId" do
    user = users(:admin)
    token = user.generate_token

    post posts_url,
         params: {
           content: "Reply to non-existent post",
           parentId: "01NONEXISTENT00000000000"
         },
         headers: { "Authorization": "Bearer #{token}" },
         as: :json

    assert_response :unprocessable_entity

    json = JSON.parse(response.body)
    assert_includes json["errors"], "Parent does not exist"
  end

  test "DELETE /posts/:id" do
    user = users(:admin)
    token = user.generate_token
    target = posts(:text_only_update)

    delete post_url(target),
           headers: { "Authorization": "Bearer #{token}" },
           as: :json

    assert_response :no_content

    assert_not_nil target.reload.deleted_at
  end

  test "DELETE /posts/:id - forbidden" do
    user = users(:dancer)
    token = user.generate_token
    target = posts(:text_only_update)

    delete post_url(target),
           headers: { "Authorization": "Bearer #{token}" },
           as: :json

    assert_response :forbidden
  end

  test "DELETE /posts/:id - unauthorized" do
    target = posts(:text_only_update)

    delete post_url(target), as: :json

    assert_response :unauthorized
  end

  test "GET /posts/:id" do
    target = posts(:text_only_update)

    get post_url(target), as: :json

    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal target.id, json["id"]
    assert_equal target.content, json["content"]
  end

  test "GET /posts/:id/replies" do
    parent = posts(:parent_post)

    get replies_post_url(parent), as: :json

    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal 1, json.length
    assert_equal posts(:child_post).id, json.first["id"]
  end

  test "GET /posts/:id/thread" do
    child = posts(:child_post)

    get thread_post_url(child), as: :json

    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal 1, json["ancestors"].length
    assert_equal posts(:parent_post).id, json["ancestors"].first["id"]
    assert_equal child.id, json["post"]["id"]
  end

  test "GET /posts/:id - includes parent and depth" do
    child = posts(:child_post)
    parent = posts(:parent_post)

    get post_url(child), as: :json

    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal 1, json["depth"]
    assert_equal 0, json["repliesCount"]
    assert_not_nil json["parent"]
    assert_equal parent.id, json["parent"]["id"]
    assert_equal parent.content, json["parent"]["content"]
  end

  test "GET /posts/:id - root post has no parent" do
    parent = posts(:parent_post)

    get post_url(parent), as: :json

    assert_response :ok

    json = JSON.parse(response.body)
    assert_equal 0, json["depth"]
    assert_nil json["parent"]
    assert_equal 1, json["repliesCount"]
  end

  test "GET /posts excludes deleted posts" do
    get posts_url, as: :json

    assert_response :ok

    refute_match posts(:deleted_post).id, response.body
  end

  test "GET /posts - authenticated user - recommended order" do
    user = users(:admin)
    token = user.generate_token

    get posts_url(limit: 100),
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :ok

    data = JSON.parse(response.body)
    posts_data = data["posts"]

    # 전체 피드 확인
    assert_operator posts_data.length, :>, 0, "피드에 게시물이 있어야 함"

    # 게시물 정보 추출
    feed = posts_data.map do |p|
      {
        id: p["id"],
        author: p["user"]["username"],
        is_self: p["user"]["id"] == user.id
      }
    end

    # 1. 본인 최신 글이 최상단인지 확인
    assert feed[0][:is_self], "첫 번째 게시물은 본인 글이어야 함"
    assert_equal posts(:admin_update).id, feed[0][:id],
                 "본인 최신 게시물(admin_update, id=002)이 최상단"

    # 2. 작성자 다양성: 같은 작성자 3번 이상 연속 금지
    consecutive_count = 1
    max_consecutive = 1
    user_ids = posts_data.map { |p| p["user"]["id"] }

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

    get posts_url(limit: 100),
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :ok

    data = JSON.parse(response.body)
    posts_data = data["posts"]

    # 본인 최신 글이 최상단
    assert_equal user.id, posts_data[0]["user"]["id"], "본인 최신 글 최상단"
    assert_equal posts(:admin_update).id, posts_data[0]["id"]

    # 작성자 다양성: 같은 작성자 3번 이상 연속으로 나오면 안 됨
    consecutive_count = 1
    max_consecutive = 1

    posts_data.map { |p| p["user"]["id"] }.each_cons(2) do |prev, curr|
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

    get posts_url(limit: 100),
        headers: { "Authorization": "Bearer #{token}" },
        as: :json

    assert_response :ok

    data = JSON.parse(response.body)
    post_ids = data["posts"].map { |p| p["id"] }

    # 같은 rank(1)의 게시물 비교: creator_post2 vs admin_update
    # dancer → creator: 10점 직접 관계
    # admin → dancer: 5점 역방향 → admin 글에 1.5점 부스트
    creator_post2_index = post_ids.index(posts(:creator_post2).id)
    admin_update_index = post_ids.index(posts(:admin_update).id)

    assert creator_post2_index < admin_update_index,
           "직접 관계(10점)가 역방향 관계(1.5점)보다 앞에 와야 함"
  end

  test "GET /posts?username - profile page" do
    get posts_url(username: "dancer", limit: 100), as: :json

    assert_response :ok

    data = JSON.parse(response.body)
    posts_data = data["posts"]

    # dancer의 게시물만 반환
    assert posts_data.all? { |p| p["user"]["username"] == "dancer" },
           "username=dancer면 dancer 게시물만 반환"

    # 최신순 정렬 (프로필 페이지)
    ids = posts_data.map { |p| p["id"] }
    assert_equal ids, ids.sort.reverse, "프로필 페이지는 최신순 정렬"
  end

  test "GET /posts?username - with pagination" do
    get posts_url(username: "dancer", limit: 1), as: :json

    assert_response :ok

    data = JSON.parse(response.body)

    assert_equal 1, data["posts"].length
    assert_not_nil data["nextCursor"], "더 있으면 nextCursor 존재"

    # 두 번째 페이지
    get posts_url(username: "dancer", limit: 1, cursor: data["nextCursor"]),
        as: :json

    second_page = JSON.parse(response.body)

    assert_equal 1, second_page["posts"].length
    refute_equal data["posts"][0]["id"], second_page["posts"][0]["id"],
                 "다른 게시물이어야 함"
  end

  test "GET /posts/:id - not found" do
    get post_url("01NONEXISTENT00000000000"), as: :json

    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "Post not found", json["error"]
  end

  test "GET /posts/:id/replies - not found" do
    get replies_post_url("01NONEXISTENT00000000000"), as: :json

    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "Post not found", json["error"]
  end

  test "GET /posts/:id/thread - not found" do
    get thread_post_url("01NONEXISTENT00000000000"), as: :json

    assert_response :not_found

    json = JSON.parse(response.body)
    assert_equal "Post not found", json["error"]
  end

  test "GET /posts - no N+1 query for parent loading" do
    queries = []
    callback = lambda { |*, payload|
      queries << payload[:sql] if payload[:sql] !~ /^(BEGIN|COMMIT|PRAGMA)/
    }

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
      get posts_url(limit: 10), as: :json
    end

    assert_response :ok

    # posts 쿼리 분석
    parent_queries = queries.select { |q| q.include?("SELECT") && q.include?("posts") }

    # includes(:user, :parent)를 사용하면:
    # 1. 메인 posts 쿼리
    # 2. parent preload 쿼리 (있는 경우)
    # 답글 개수만큼 추가 쿼리가 발생하지 않음 (N+1 방지)
    assert_operator parent_queries.length, :<=, 2,
                    "N+1 없이 최대 2개 쿼리여야 함. 실제: #{parent_queries.length}"
  end
end
