require 'open-uri'
require 'yaml'

module OmniFocus::Github
  VERSION = '1.0.0'

  GH_URL = "http://github.com"

  def fetch url, key
    base_url = "#{GH_URL}/api/v2/yaml"
    YAML.load(URI.parse("#{base_url}/#{url}").read)[key]
  end

  def populate_github_tasks
    user  = `git config --global github.user`.chomp
    projects = fetch("repos/show/#{user}", "repositories").select { |project|
      project[:open_issues] > 0
    }.map { |project|
      project[:name]
    }

    projects.sort.each do |project|
      fetch("issues/list/#{user}/#{project}/open", "issues").each do |issue|
        number    = issue["number"]
        ticket_id = "GH-#{project}##{number}"
        title     = "#{ticket_id}: #{issue["title"]}"
        url       = "#{GH_URL}/#{user}/#{project}/issues/#issue/#{number}"

        if existing[ticket_id] then
          bug_db[existing[ticket_id]][ticket_id] = true
          next
        end

        bug_db[project][ticket_id] = [title, url]
      end
    end
  end
end
