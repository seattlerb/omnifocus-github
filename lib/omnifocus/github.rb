require 'open-uri'
require 'json'

module OmniFocus::Github
  VERSION = '1.2.0'
  PREFIX  = "GH"

  def populate_github_tasks
    # curl -i -u "#{user}:#{pass}" "https://api.github.com/issues"

    user = `git config --global github.user`.chomp
    pass = `git config --global github.password`.chomp
    uri  = URI.parse "https://api.github.com/issues"
    body = uri.read :http_basic_authentication => [user, pass]

    JSON.parse(body).each do |issue|
      number    = issue["number"]
      url       = issue["html_url"]
      project   = url.split(/\//)[-3]
      ticket_id = "#{PREFIX}-#{project}##{number}"
      title     = "#{ticket_id}: #{issue["title"]}"

      if existing[ticket_id] then
        bug_db[existing[ticket_id]][ticket_id] = true
        next
      end

      bug_db[project][ticket_id] = [title, url]
    end
  end
end
