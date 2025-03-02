# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'rspec'
require 'database_cleaner/sequel'
require_relative '../app/start'

RSpec.describe 'Start' do
  include Rack::Test::Methods

  DatabaseCleaner.strategy = :transaction

  def app
    Sinatra::Application
  end

  before(:each) do
    DatabaseCleaner.start
  end

  after(:each) do
    DatabaseCleaner.clean
  end

  let(:user_id) { 1 }

  let(:params11) do
    { "user_id": user_id,
      "positions": [
        {
          "id": 1,
          "price": 100,
          "quantity": 3
        },
        {
          "id": 2,
          "price": 50,
          "quantity": 2
        },
        {
          "id": 3,
          "price": 40,
          "quantity": 1
        },
        {
          "id": 4,
          "price": 150,
          "quantity": 2
        }
      ] }.transform_keys(&:to_sym)
  end

  let(:params21) do
    {
      "user": {
        "id": user_id,
        "template_id": 1,
        "name": 'Иван',
        "bonus": '100.0'
      },
      "operation_id": 16,
      "write_off": 50
    }.transform_keys(&:to_sym)
  end

  it 'выполнить post запрос /operation без параметров' do
    post '/operation'

    expect(last_response.status).to eq(404)
  end

  context 'для пользователя id=1 c лояльность Bronze' do
    it 'созадать операцию' do
      cnt = Operation.count
      post '/operation', JSON.generate(params11), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['status']).to eq(200)
      expect(Operation.count).to eq(cnt + 1)
      expect(Operation.last[:user_id]).to eq(params11[:user_id])
    end

    it 'подтвердить операцию' do
      post '/operation', JSON.generate(params11), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['status']).to eq(200)

      params21[:operation_id] = Operation.last[:id]

      post '/submit', JSON.generate(params21), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['status']).to eq(200)
    end
  end

  context 'для пользователя id=2 c лояльность Silver' do
    let!(:user_id) { 2 }

    it 'подтвердить операцию' do
      post '/operation', JSON.generate(params11), 'CONTENT_TYPE' => 'application/json'

      expect(JSON.parse(last_response.body)['status']).to eq(200)

      params21[:operation_id] = Operation.last[:id]
      params21[:write_off] = 100

      post '/submit', JSON.generate(params21), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['status']).to eq(200)
    end
  end

  context 'для пользователя id=3 c лояльность Gold' do
    let!(:user_id) { 3 }

    it 'подтвердить операцию' do
      post '/operation', JSON.generate(params11), 'CONTENT_TYPE' => 'application/json'

      expect(JSON.parse(last_response.body)['status']).to eq(200)

      params21[:operation_id] = Operation.last[:id]
      params21[:write_off] = 100

      post '/submit', JSON.generate(params21), 'CONTENT_TYPE' => 'application/json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['status']).to eq(200)
    end
  end
end
