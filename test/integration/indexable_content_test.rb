require_relative '../test_helper'

class IndexableContentTest < ActiveSupport::TestCase
  setup do
    stub_shared_component_locales
  end

  should 'generate at least one keyword for each flow' do
    flow_presenters = RegisterableSmartAnswers.new.flow_presenters
    flow_presenters.each do |flow_presenter|
      assert flow_presenter.indexable_content.split(' ').any?
    end
  end
end
