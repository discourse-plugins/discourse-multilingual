# frozen_string_literal: true

require 'rails_helper'

describe TopicCreator do
  fab!(:staff) { Fabricate(:moderator) }
  fab!(:user)  { Fabricate(:user) }
  fab!(:tag)  { Fabricate(:tag) }
  fab!(:topic) { Fabricate(:topic, title: 'Topic title test', custom_fields: {}) }

  let(:valid_attrs) { Fabricate.attributes_for(:topic) }
  let(:message) { 'hello' }

  SiteSetting.tagging_enabled = true
  SiteSetting.multilingual_enabled = true
  SiteSetting.multilingual_content_languages_enabled = true

  Multilingual::ContentTag.update_all

  context 'when a language tag is required' do
    before(:each) do
      SiteSetting.multilingual_require_content_language_tag = 'yes'
    end

    it "should rollback when no tags are present" do
      expect do
        TopicCreator.create(user, Guardian.new(user), valid_attrs)
      end.to raise_error(ActiveRecord::Rollback)
    end

    it "should rollback when only non language tags are present" do
      expect do
        TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [tag.name]))
      end.to raise_error(ActiveRecord::Rollback)
    end

    it "should work when a language tag is present" do
      attrs = valid_attrs.merge(content_language_tags: [Multilingual::ContentTag.all.first])
      topic = TopicCreator.create(user, Guardian.new(user), attrs)
      expect(topic).to be_valid
    end

    it "should work when a language tag and a non language tag is present" do
      attrs = valid_attrs.merge(content_language_tags: [tag.name, Multilingual::ContentTag.all.first])
      topic = TopicCreator.create(user, Guardian.new(user), attrs)
      expect(topic).to be_valid
    end

    context 'when staff are exempt' do
      before(:each) do
        SiteSetting.multilingual_require_content_language_tag = 'non-staff'
      end

      it "should work when user is staff and no language tag is present" do
        topic = TopicCreator.create(staff, Guardian.new(staff), valid_attrs.merge(tags: [tag.name]))
        expect(topic).to be_valid
      end

      it "should rollback when user is not staff and no language tag is present" do
        expect do
          TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [tag.name]))
        end.to raise_error(ActiveRecord::Rollback)
      end
    end
  end

  context 'when no language tag is required' do
    before(:each) do
      SiteSetting.multilingual_require_content_language_tag = 'no'
    end

    it "should work when no tags are present" do
      topic = TopicCreator.create(user, Guardian.new(user), valid_attrs)
      expect(topic).to be_valid
    end

    it "should work when no language tag is present" do
      topic = TopicCreator.create(user, Guardian.new(user), valid_attrs.merge(tags: [tag.name]))
      expect(topic).to be_valid
    end
  end
end
