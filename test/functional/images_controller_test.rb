require File.dirname(__FILE__) + '/../test_helper'
require 'images_controller'

# Re-raise errors caught by the controller.
class ImagesController; def rescue_action(e) raise e end; end

class ImagesControllerTest < Test::Unit::TestCase
  # fixtures are preloaded if necessary
  def setup
    @controller = ImagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
