require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  test "GET /posts" do
    get posts_url, as: :json

    assert_response :ok

    assert_match posts(:text_only_update).id, response.body
    assert_match posts(:text_only_update).content, response.body
  end
end
