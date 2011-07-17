require 'open-uri'
require 'yaml'

module OmniFocus::Github
  VERSION = '1.0.1'

  GH_URL = "https://github.com"

  def fetch url, key
    base_url = "#{GH_URL}/api/v2/yaml"
    YAML.load(URI.parse("#{base_url}/#{url}").read)[key]
  end

  def populate_github_tasks
    user  = `git config --global github.user`.chomp

    # Personal projects
    projects = fetch("repos/show/#{user}", "repositories").select { |project|
      project[:open_issues] > 0
    }.map { |project|
      project[:name]
    }

    projects.sort.each do |project|
      warn "  scanning #{user}/#{project}"
      fetch("issues/list/#{user}/#{project}/open", "issues").each do |issue|
        number    = issue["number"]
        ticket_id = "GH-#{project}##{number}"
        title     = "#{ticket_id}: #{issue["title"]}"
        url       = "#{GH_URL}/#{user}/#{project}/issues/#{number}"

        if existing[ticket_id] then
          bug_db[existing[ticket_id]][ticket_id] = true
          next
        end

        bug_db[project][ticket_id] = [title, url]
      end
    end

    # Organization projects
    orgs = fetch("user/show/#{user}/organizations", "organizations")
    orgs.each do |o|
      login = o["login"]
      projects = fetch("repos/show/#{login}", "repositories")
      projects = projects.select { |project| project[:open_issues] > 0}
      projects = projects.map{|project| project[:name]}

      projects.sort.each do |project|
        warn "  scanning #{login}/#{project}"
        issues = fetch("issues/list/#{login}/#{project}/open", "issues")
        issues.each do |issue|
          number    = issue["number"]
          t_user    = issue["user"]
          ticket_id = "GH-#{project}##{number}"
          title     = "#{ticket_id}: #{issue["title"]}"
          url       = "#{GH_URL}/#{login}/#{project}/issues/#issue/#{number}"

          next unless t_user == user
          if existing[ticket_id] then
            bug_db[existing[ticket_id]][ticket_id] = true
            next
          end

          bug_db[project][ticket_id] = [title, url]
        end
      end
    end
  end
end
