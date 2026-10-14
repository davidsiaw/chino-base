# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ChinoBase smoke', type: :feature do
  before { visit '/' }

  it 'serves the SPA shell' do
    expect(page).to have_title('ChinoBase')
  end

  it 'boots Cappuccino and renders the Hello World label' do
    wait_for_cappuccino
    wait_for_cappuccino_text('Hello World!')
  end

  it 'shows the standard menu bar' do
    wait_for_cappuccino
    expect(cappuccino_menu_bar_visible?).to be(true)
    expect(cappuccino_main_menu_titles).not_to be_empty
  end
end
