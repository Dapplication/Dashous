require 'feature_helper'

feature 'search for trade requests', js: true do
  given!(:user1) { create :user }
  given!(:user2) { create :user }
  given!(:trade_request1) do
    create :trade_request, :new_york,
      user: user1,
      name: 'My Trade',
      kind: 'sell',
      profit: '10'
  end
  given!(:trade_request2) do
    create :trade_request, :stamford,
      user: user2,
      name: "Another Guy's Trade",
      kind: 'buy',
      profit: '20'
  end
  given!(:trade_request3) do
    create :trade_request, :stamford,
      user: user2,
      name: "Another Guy's Disabled Trade",
      active: false,
      kind: 'buy',
      profit: '20'
  end
  given!(:geocode) { GeoHelper.define_stub 'New York City, New York', :geolocate_newyork }
  given!(:geocode2) { GeoHelper.define_stub 'Stamford, New York', :geolocate_stamford }
  given!(:current_price) { stub_price(8.34) }

  context 'unauthenticated' do
    Steps 'I search for trade requests' do
      Given 'location lookup by ip will be Butte' do
        expect_any_instance_of(QueryService).to receive(:query).once.and_return('Stamford, New York')
      end
      When 'I am on the homepage' do
        visit '/'
      end
      Then 'I should no search results' do
        should_see 'Search Results'
        should_see 'You can use the search tool (above) to find people that want to trade in a specific location!'
        should_see 'Or if you like, we can guess your location:'
        should_see '1 Dash = $8.34'
      end
      When 'I ask dashous to guess my location' do
        click_button 'Guess my location'
      end
      Then 'I should see the query input prefilled with my local city' do
        should_see 'My Trade'
        expect(page).to have_field('query', with: 'Stamford, New York')
      end
      When 'I enter in my location' do
        fill_in :query, with: 'New York City, New York'
      end
      And 'I submit the form' do
        find('.search-button').click
      end
      Then 'I should see search results' do
        should_see 'Search Results'
        should_not_see "Another Guy's Disabled Trade"
        within '.table-list .row:first-child' do
          should_see 'My Trade'
          should_see '0.0 miles E'
          should_see 'Selling $9.17'
        end
        within '.table-list .row:last-child' do
          should_see "Another Guy's Trade"
          should_see '121.2 miles N'
          should_see 'Buying'
          should_see '$6.67'
        end
      end
      When "I click on the other guy's trade request" do
        find('.table-list .row:last-child').click
      end
      Then 'I should see the public trade request page' do
        within '.content h1' do
          should_see "Another Guy's Trade"
        end
        should_be_located '/t/another_guys_trade'
      end
    end

    context 'there are no Trade Requests in your area' do
      given!(:trade_request1) { nil }
      given!(:trade_request2) { nil }
      given!(:trade_request3) { nil }

      Steps 'I search for trade requests' do
        Given 'location lookup by ip will be Butte' do
          expect_any_instance_of(QueryService).to receive(:query).once.and_return('Stamford, New York')
        end
        When 'I am on the homepage' do
          visit '/'
        end
        Then 'I should no search results' do
          should_see 'Search Results'
          should_see 'You can use the search tool (above) to find people that want to trade in a specific location!'
          should_see 'Or if you like, we can guess your location:'
          should_see '1 Dash = $8.34'
        end
        When 'I ask dashous to guess my location' do
          click_button 'Guess my location'
        end
        Then 'I should see the query input prefilled with my local city' do
          expect(page).to have_field('query', with: 'Stamford, New York')
        end
        And 'I should not see the messaging telling me how to search' do
          should_see 'Search Results'
          should_not_see 'You can use the search tool (above) to find people that want to trade in a specific location!'
          should_not_see 'Or if you like, we can guess your location:'
        end
        And 'I should be encouraged to create an account and create a new Trade request' do
          within '.empty-state' do
            should_see 'It looks like no Trade Requests were found near you.'
            should_see 'Be the first to create a Trade Request in your area!'
            should_see 'Signup'
            should_see "( it's free )"
          end
        end
        When 'I click signup' do
          within '.empty-state' do
            click_link 'Signup'
          end
        end
        Then 'I should be on the signup page' do
          should_be_located '/signup'
        end
      end
    end
  end

  context 'authenticated' do

    background do
      login_as user1
    end

    context 'there are no Trade Requests in your area' do
      given!(:trade_request1) { nil }
      given!(:trade_request2) { nil }
      given!(:trade_request3) { nil }

      Steps 'I search for trade requests' do
        Given 'location lookup by ip will be Butte' do
          expect_any_instance_of(QueryService).to receive(:query).once.and_return('Stamford, New York')
        end
        When 'I am on the homepage' do
          visit '/'
        end
        Then 'I should no search results' do
          should_see 'Search Results'
          should_see 'You can use the search tool (above) to find people that want to trade in a specific location!'
          should_see 'Or if you like, we can guess your location:'
          should_see '1 Dash = $8.34'
        end
        When 'I ask dashous to guess my location' do
          click_button 'Guess my location'
        end
        Then 'I should see the query input prefilled with my local city' do
          expect(page).to have_field('query', with: 'Stamford, New York')
        end
        And 'I should not see the messaging telling me how to search' do
          should_see 'Search Results'
          should_not_see 'You can use the search tool (above) to find people that want to trade in a specific location!'
          should_not_see 'Or if you like, we can guess your location:'
        end
        And 'I should be encouraged to create an account and create a new Trade request' do
          within '.empty-state' do
            should_see 'It looks like no Trade Requests were found near you.'
            should_see 'Be the first to create a Trade Request in your area!'
            should_not_see 'Signup'
            should_not_see "( it's free )"
          end
        end
        When 'I click signup' do
          within '.empty-state' do
            click_link 'Create Trade Request'
          end
        end
        Then 'I should be on the signup page' do
          should_be_located new_trade_request_path
        end
      end
    end
  end
end
