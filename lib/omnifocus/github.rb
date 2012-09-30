require 'open-uri'
require 'json'

module OmniFocus::Github
  VERSION = '1.3.0'
  PREFIX  = "GH"

  def populate_github_tasks
    api = omnifocus_git_param :api, "https://api.github.com"
    # Either token or user + password is required. If both
    # are present, token is used.
    auth = {
      :user => omnifocus_git_param(:user),
      :password => omnifocus_git_param(:password),
      :token => omnifocus_git_param(:token),
    }

    body = fetch api, auth, 1

    process body

    (2..get_last(body)).each do |page|
      process fetch api, auth, page
    end
  end

  def omnifocus_git_param name, default = nil
    param = `git config --global omnifocus-github.#{name}`.chomp
    param.empty? ? default : param
  end

  def fetch api, auth, page
    uri = URI.parse "#{api}/issues?page=#{page}"
    if auth[:token]
      uri.read "Authorization" => "token #{auth[:token]}"
    elsif auth[:user] && auth[:password]
      uri.read :http_basic_authentication => [auth[:user], auth[:password]]
    else
      raise ArgumentError, "Missing authentication"
    end
  end

  def get_last body
    link, last = body.meta["link"], nil
    link and link[/page=(\d+).. rel=.last/, 1].to_i or 0
  end

  def process body
    JSON.parse(body).each do |issue|
      pr        = issue["pull_request"] && !issue["pull_request"]["diff_url"].nil?
      number    = issue["number"]
      url       = issue["html_url"]
      body      = issue["body"]
      project   = url.split(/\//)[-3]
      ticket_id = "#{PREFIX}-#{project}##{number}"
      title     = "#{ticket_id}: #{pr ? "[PR] " : ""}#{issue["title"]}"

      if existing[ticket_id] then
        bug_db[existing[ticket_id]][ticket_id] = true
        next
      end

      bug_db[project][ticket_id] = [title, "#{url}\n\n#{body}"]
    end
  end
end
