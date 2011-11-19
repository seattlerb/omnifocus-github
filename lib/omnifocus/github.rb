require 'open-uri'
require 'json'

module OmniFocus::Github
  VERSION = '1.3.0'
  PREFIX  = "GH"

  def populate_github_tasks
    # curl -i -u "#{user}:#{pass}" "https://api.github.com/issues?page=1"

    user = `git config --global github.user`.chomp
    pass = `git config --global github.password`.chomp

    body = fetch user, pass, 1

    process body

    (2..get_last(body)).each do |page|
      process fetch user, pass, page
    end
  end

  def fetch user, pass, page
    uri = URI.parse "https://api.github.com/issues?page=#{page}"
    uri.read :http_basic_authentication => [user, pass]
  end

  def get_last body
    link, last = body.meta["link"], nil
    link and link[/page=(\d+).. rel=.last/, 1].to_i or 0
  end

  def process body
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
