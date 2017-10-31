require 'test_helper'

class ProjectionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get projections_index_url
    assert_response :success
  end

end
