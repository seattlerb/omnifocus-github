require 'open-uri'
require 'yaml'
require 'json'

module OmniFocus::Github
  VERSION = '1.0.2'

  PREFIX = "GH"
  GH_URL = "https://github.com"
  GH_API_URL = "https://api.github.com"

  def fetch url, key, ver = 2
    base_url = "#{GH_URL}/api/v#{ver}/yaml"
    YAML.load(URI.parse("#{base_url}/#{url}").read)[key]
  end

  def fetch3 url
    JSON.parse(URI.parse("#{GH_API_URL}/#{url}").read)
  end

  def populate_github_tasks
    @filter = ARGV.shift

    bug_db.delete_if do |k,v|
      not k.index @filter
    end if @filter

    @user = user = `git config --global github.user`.chomp

    # Personal projects
    projects = fetch("repos/show/#{user}", "repositories").select { |project|
      project[:open_issues] > 0
    }.map { |project|
      project[:name]
    }

    projects.sort.each do |project|
      populate_issues_for user, project
    end

    # Organization projects
    fetch("user/show/#{user}/organizations", "organizations").each do |org|
      login = org["login"]
      projects = fetch("repos/show/#{login}", "repositories")
      projects = projects.select { |project| project[:open_issues] > 0}
      projects = projects.map{|project| project[:name]}

      projects.sort.each do |project|
        populate_issues_for login, project
      end
    end
  end

  def populate_issues_for user_org, project
    return unless project.index @filter if @filter

    warn "  #{user_org}/#{project}"

    fetch3("repos/#{user_org}/#{project}/issues").each do |issue|
      next unless issue["assignee"]

      number    = issue["number"]
      t_user    = begin
                    issue["assignee"]["login"]
                  rescue NoMethodError
                    pp issue
                  end
      ticket_id = "#{PREFIX}-#{project}##{number}"
      title     = "#{ticket_id}: #{issue["title"]}"
      url       = "#{GH_URL}/#{user_org}/#{project}/issues/#{number}"

      next unless t_user == @user

      if existing[ticket_id] then
        bug_db[existing[ticket_id]][ticket_id] = true
        next
      end

      bug_db[project][ticket_id] = [title, url]
    end
  end
end
