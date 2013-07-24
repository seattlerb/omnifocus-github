require 'octokit'

module OmniFocus::Github
  VERSION = "1.6.0"
  PREFIX  = "GH"

  def populate_github_tasks
    omnifocus_git_param(:accounts, "github").split(/\s+/).each do |account|
      endpoints = {}
      endpoints[:api] = omnifocus_git_param(:api, nil, account)
      endpoints[:web] = omnifocus_git_param(:web, nil, account)

      # User + password is required
      auth = {
        :user => omnifocus_git_param(:user, nil, account),
        :password => omnifocus_git_param(:password, nil, account),
      }
      unless (auth[:user] && auth[:password])
        warn "Missing authentication parameters for account #{account}."
        next
      end

      account_label = account == "github" ? nil : account

      process(account_label, gh_client(account, auth, endpoints))
    end
  end

  def omnifocus_git_param name, default = nil, prefix = "omnifocus-github"
    param = `git config --global #{prefix}.#{name}`.chomp
    param.empty? ? default : param
  end

  def gh_client account, auth, endpoints
    if account != "github"
      if endpoints[:api] && endpoints[:web]
        Octokit.configure do |c|
          c.api_endpoint = endpoints[:api]
          c.web_endpoint = endpoints[:web]
        end
      else
        raise ArgumentError, "api and web endpoint configs required for github enterprise"
      end
    end

    if auth[:user] && auth[:password]
      client = Octokit::Client.new(:login => auth[:user],
                                   :password => auth[:password])

      client.user(auth[:user])
    else
      raise ArgumentError, "Missing authentication"
    end
    client
  end

  def process account, client
    client.user_issues.each do |issue|
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
