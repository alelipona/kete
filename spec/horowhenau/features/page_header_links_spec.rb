require 'spec_helper'

feature "Page Header Basket-Links" do
  it "Adopt an Anzac can be followed" do
    visit "/"
    click_link('Adopt an Anzac')
    expect(page.status_code).to be(200)
    expect(current_url).to end_with("/en/adopt_an_anzac")
  end

  it "Trevor Heath Photography can be followed" do
    visit "/"
    click_link "Trevor Heath Photography"
    expect(page.status_code).to be(200)
    expect(current_url).to end_with("/en/trevor_heath_photography")
  end

  it "Chinese Remembered can be followed" do
    visit "/"
    click_link "Chinese Remembered"
    expect(page.status_code).to be(200)
    expect(current_url).to end_with("/en/chinese_remembered")
  end

  it "Ricky can be followed" do
    visit "/"
    click_link "Ricky"
    expect(page.status_code).to be(200)
    expect(current_url).to end_with("/en/ricky")
  end
end

feature "Page header navigation Links" do
  it "Home can be followed" do
    visit "/"
    click_link "Home"
    expect(page.status_code).to be(200)
    expect(current_url).to end_with("/en/site")
  end

  it "Browse can be followed" do
    visit "/"
    click_link "Browse"
    expect(page.status_code).to be(200)
    expect(current_url).to end_with("/en/site/search/all/?controller_name_for_zoom_class=Topic&urlified_name=site")

  end

  it "About can be followed" do
    visit "/"
    click_link "About"
    expect(page.status_code).to be(200)
    expect(current_url).to end_with("/en/about")
    expect(page).to have_content("About Kete Horowhenua")
    expect(page).not_to have_content("CONTENT_WRAPPER_END SHOULD BE REMOVED")
  end

  it "Help can be followed" do
    visit "/"
    click_link "Help"
    expect(page.status_code).to be(200)
    expect(current_url).to end_with("/en/help")
    expect(page).to have_content("IntroductionKete Horowhenua is a community built digital library of arts")
    expect(page).not_to have_content("CONTENT_WRAPPER_END SHOULD BE REMOVED")

  end

  it "Contact opens an email" do
    visit "/"
    contact_link = find_link("Contact")[:href]
    expect(contact_link).to eq("mailto:kete@library.org.nz")
  end
end
