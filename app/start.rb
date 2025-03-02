# frozen_string_literal: true

require 'sinatra'
require_relative './models/base'

post '/operation' do
  params = request.body.read

  return answer(Result.error('В запросе нет параметров!')) if params.empty?

  answer Operation.calculate JSON.parse(params, symbolize_names: true)
end

post '/submit' do
  params = request.body.read

  return answer(Result.error('В запросе нет параметров!')) if params.empty?

  answer Operation.submit JSON.parse(params, symbolize_names: true)
end

def answer(res)
  if res.success?
    content_type 'apllication/json'
    status 200
    res.ans.to_json
  else
    content_type 'text/html'
    status 404
    res.error
  end
end
