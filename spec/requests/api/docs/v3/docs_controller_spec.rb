# frozen_string_literal: true

describe Api::Docs::V3::DocsController, type: :request do
  describe "#decision_reviews" do
    it "should successfully return openapi spec" do
      get "/api/docs/v3/decision_reviews"
      expect(response).to have_http_status(200)
      json = JSON.parse(response.body)
      expect(json["openapi"]).to eq("3.0.0")
    end
    describe "/higher_level_reviews documentation" do
      before(:each) do
        get "/api/docs/v3/decision_reviews"
      end
      let(:hlr_doc) do
        json = JSON.parse(response.body)
        json["paths"]["/higher_level_reviews"]
      end
      it "should have POST" do
        expect(hlr_doc).to include("post")
      end
    end
    describe "/higher_level_reviews/intake_status/{uuid} documentation" do
      before(:each) do
        get "/api/docs/v3/decision_reviews"
      end
      let(:hlr_intake_status_doc) do
        json = JSON.parse(response.body)
        json["paths"]["/higher_level_reviews/intake_status/{uuid}"]
      end
      it "should have GET" do
        expect(hlr_intake_status_doc).to include("get")
      end
    end
    describe "/higher_level_reviews/{uuid} documentation" do
      before(:each) do
        get "/api/docs/v3/decision_reviews"
      end
      let(:hlr_intake_status_doc) do
        json = JSON.parse(response.body)
        json["paths"]["/higher_level_reviews/{uuid}"]
      end
      it "should have GET" do
        expect(hlr_intake_status_doc).to include("get")
      end
    end
  end
end
