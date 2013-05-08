require 'open-uri'
require 'json'

module OmniFocus::Github
  VERSION = "1.4.1"
  PREFIX  = "GH"

  GH_API_DEFAULT = "https://api.github.com"

  def populate_github_tasks
    omnifocus_git_param(:accounts, "github").split(/\s+/).each do |account|
      api = omnifocus_git_param(:api, GH_API_DEFAULT, account)
      # User + password is required
      auth = {
        :user => omnifocus_git_param(:user, nil, account),
        :password => omnifocus_git_param(:password, nil, account),
        :token => omnifocus_git_param(:token, nil, account),
      }
      unless (auth[:user] && auth[:password])
        warn "Missing authentication parameters for account #{account}."
        next
      end

      # process will omit the account label if nil.
      # Supply nil for the default "github" account for compatibility
      # with previous versions.
      account_label = account == "github" ? nil : account

      body = fetch(api, auth, 1)
      process(account_label, body)
      (2..get_last(body)).each do |page|
        process(account_label, fetch(api, auth, page))
      end
    end
  end

  def omnifocus_git_param name, default = nil, prefix = "omnifocus-github"
    param = `git config --global #{prefix}.#{name}`.chomp
    param.empty? ? default : param
  end

  def fetch api, auth, page
    uri = URI.parse "#{api}/issues?page=#{page}"

    headers = {
      "User-Agent"=>"omnifocus-github/#{VERSION}"
    }

    if auth[:user] && auth[:password]
      headers[:http_basic_authentication] = [auth[:user], auth[:password]]
    else
      raise ArgumentError, "Missing authentication"
    end

    uri.read headers
  end

  def get_last body
    link, last = body.meta["link"], nil
    link and link[/page=(\d+).. rel=.last/, 1].to_i or 0
  end

  def process account, body
    JSON.parse(body).each do |issue|
      pr        = issue["pull_request"] && !issue["pull_request"]["diff_url"].nil?
      number    = issue["number"]
      url       = issue["html_url"]
      project   = [account, url.split(/\//)[-3]].compact.join("-")
      ticket_id = "#{PREFIX}-#{project}##{number}"
      title     = "#{ticket_id}: #{pr ? "[PR] " : ""}#{issue["title"]}"
      note      = "#{url}\n\n#{issue["body"]}"

      if existing[ticket_id] then
        bug_db[existing[ticket_id]][ticket_id] = true
        next
      end

      bug_db[project][ticket_id] = [title, note]
    end
  end
end
