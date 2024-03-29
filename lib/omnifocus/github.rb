old_w, $-w = $-w, nil # don't you just hate sloppy developers?
require "octokit"
$-w = old_w

Octokit.auto_paginate = true

module OmniFocus::Github
  VERSION = "2.0.0"
  PREFIX  = "GH"

  def populate_github_tasks
    processed = false

    github_clients.each do |account, client|
      account_label = account == "github" ? PREFIX : account

      processed = true
      process account_label, client
    end

    raise "No accounts authenticated. Bailing." unless processed
  end

  def github_clients
    omnifocus_git_param(:accounts, "github").split(/\s+/).map { |account|
      endpoints = {}
      endpoints[:api] = omnifocus_git_param(:api, nil, account)
      endpoints[:web] = omnifocus_git_param(:web, nil, account)

      # User + password is required
      auth = {
        :name     => omnifocus_git_param(:name,         nil, account),
        :user     => omnifocus_git_param(:user,         nil, account),
        :password => omnifocus_git_param(:password,     nil, account),
        :oauth    => omnifocus_git_param("oauth-token", nil, account),
      }

      unless auth[:user] && (auth[:password] || auth[:oauth])
        warn "Missing authentication parameters for account #{account}."
        next
      end

      auth[:name] = auth[:user] if auth[:name].nil?

      client = nil

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

        client.user auth[:name]
      elsif auth[:user] && auth[:oauth]
        client = Octokit::Client.new :access_token => auth[:oauth]
        client.user.login
      else
        raise ArgumentError, "Missing authentication"
      end

      [account, client]
    }.to_h
  end

  def omnifocus_git_param name, default = nil, prefix = "omnifocus-github"
    param = `git config #{prefix}.#{name}`.chomp
    param.empty? ? default : param
  end

  def process prefix, client
    client.list_issues.each do |issue|
      pr        = issue["pull_request"] && !issue["pull_request"]["diff_url"].nil?
      number    = issue.number
      project   = issue.repository.full_name.split("/").last
      ticket_id = "#{prefix}-#{project}##{number}"
      title     = "#{ticket_id}: #{pr ? "[PR] " : ""}#{issue["title"]}"
      # HACK
      url       = "https://github.com/#{issue.repository.full_name}/issues/#{number}"
      note      = "#{url}\n\n#{issue["body"]}"

      next if excluded_projects.include? project

      if existing[ticket_id] then
        bug_db[project][ticket_id] = true
        next
      end

      bug_db[project][ticket_id] = [title, note]
    end
  end
end
