ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "minitest/reporters"
Minitest::Reporters.use!
require "fileutils"

require_relative "../cms"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def admin_session
    { "rack.session" => { signed_in: true } }
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"

    get "/"
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"
  end

  def test_file
    create_document "changes.txt", "These are the changes"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_equal "These are the changes", last_response.body
  end

  def test_no_file
    get "/channnges.txt"
    assert_equal 302, last_response.status

    assert_equal "channnges.txt does not exist", session[:alert]
  end

  def test_markdown
    create_document "about.md", "<h1>This is a heading</h1>"

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>This is a heading</h1>"
  end

  def test_editing_document
    create_document "about.md"

    get "/about.md/edit", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_editing_document_signed_out
    create_document "changes.txt"

    get "/changes.txt/edit"

    assert_equal 302, last_response.status
    assert_equal "You need to be signed in to make changes.", session[:alert]
  end

  def test_updating_document
    post "/changes.txt/edit", {file_content: "new content" }, admin_session

    assert_equal 302, last_response.status

    assert_equal "changes.txt has been updated.", session[:alert]

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_view_new_document_form
    get "/new", {}, admin_session

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<input name="file_name")
  end

  def test_new_document_error
    post "/new", { file_name: "" }, admin_session

    assert_equal 422, last_response.status

    assert_includes last_response.body, "Please enter a file name"
  end

  def test_new_document_success
    post "/new", { file_name: "new_file.txt" }, admin_session

    assert_equal 302, last_response.status

    assert_equal "new_file.txt has been created.", session[:alert]

    get "/"
    assert_includes last_response.body, %q(<a href="/new_file.txt/edit">)
  end

  def test_delete
    create_document "changes.txt"

    post "/changes.txt/delete", {}, admin_session
    assert_equal 302, last_response.status
    assert_equal "changes.txt has been deleted.", session[:alert]

    get "/"
    get "/", {}, admin_session
    refute_includes last_response.body, "changes.txt"
  end

  def test_sign_in_page
    get "/sign_in"

    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<input name="user_name")
  end

  def test_sign_in_success
    post "/sign_in", {}, admin_session

    assert_equal true, session[:signed_in]
  end

  def test_sign_in_failure
    post "/sign_in", user_name: "", password: "password"

    assert_equal 422, last_response.status
    assert_nil session[:signed_in]
    assert_includes last_response.body, "Invalid credentials"
  end

  def test_sign_out
    get "/", {}, admin_session
    assert_includes last_response.body, "Signed in"

    post "/sign_out"
    assert_equal "You have been signed out.", session[:alert]

    get last_response["Location"]
    assert_equal false, session[:signed_in]
    assert_includes last_response.body, "Sign In"
  end

end
















