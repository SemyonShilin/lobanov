require 'rails_helper'

RSpec.describe FruitsController, type: :request do
  describe 'GET #show' do
    it 'returns expected resource', :lobanov do
      get('/wapi/fruits/2?q=with_null_name')

      expect(response).to have_http_status(:ok)
      expect(json_body).to eq({color: 'yellow', name: nil, weight: 50, seasonal: false})
    end
  end
end