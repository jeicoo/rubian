require 'yaml'
require 'sinatra'
require 'json'
require 'faraday'
require 'faraday_middleware'
require 'sys/proctable'
include Sys

configure do
  set :bind, '0.0.0.0'
end

url = 'https://api.stackexchange.com/2.2'
$conn = Faraday.new(url: url, request: { timeout: 5 }) do |faraday|
  faraday.response :json
  faraday.adapter Faraday.default_adapter
end

$processes = YAML.load_file('config.yaml')['processes']


get '/' do
  @top_questions = get_top_questions 
  @ps = get_cpu_usage
  erb :index
end


def get_top_questions
  response = $conn.get('search', intitle: 'grafana', site: 'stackoverflow').body
  questions = response['items'].sort_by {|question| -question['view_count']}

  top_questions = []
  questions[0...10].each do |question|
    q = { :link => question['link'],
          :view_count => question['view_count'],
          :title => question['title'] }
    top_questions << q
  end
  top_questions
end


def get_cpu_usage
  ps = ProcTable.ps
  ps_cpu_usage = []
  $processes.each do |process_name|
    matched_ps = ps.select {|p| p.name == process_name}
    matched_ps.each do |p|
      ps_cpu_usage << { :pname => p.name, :pid => p.pid, :cpu => p.pctcpu }
    end
  end
  ps_cpu_usage
end
