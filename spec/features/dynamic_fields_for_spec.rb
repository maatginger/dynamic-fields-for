describe DynamicFieldsFor do
  describe '#fields_for' do
    def expect_result(user)
      expect(page).to have_button('Update User')
      expect(user.roles.map(&:role_name)).to match_array(['role 0', 'new role 0', 'new role 1'])
    end

    def role_inputs
      all('[name$="[role_name]"]')
    end

    def remove_role_links
      all('a', text: 'Remove role')
    end

    def email_inputs
      all('[name$="[email]"]')
    end

    def remove_email_links
      all('a', text: 'Remove recipient')
    end

    def deal_with_dynamic_roles
      expect{remove_role_links.last.click}.to change{remove_role_links.size}.from(3).to(2)
      expect{2.times{ click_link 'Add role'}}.to change{remove_role_links.size}.to(4)
      expect{remove_role_links.last.click}.to change{remove_role_links.size}.to(3)
      expect{click_link 'Add role'}.to change{remove_role_links.size}.to(4)
      expect{remove_role_links[1].click}.to change{remove_role_links.size}.to(3)

      role_inputs.last(2).each_with_index do |element, index|
        element.set("new role #{index}")
      end
    end

    let(:user){User.first}

    %w(form_for simple_form_for).each do |form_type|
      context form_type do

        it 'should pass for new object' do
          visit "/users/new"

          within("##{form_type}") do
            deal_with_dynamic_roles

            fill_in 'user[user_name]', with: 'New user'
            role_inputs.first.set('role 0')

            click_button 'Create User'
          end

          expect_result(User.find(URI.parse(current_url).path.match(/users\/(\d+)\/edit/)[1]))
        end

        it 'should pass for existing object' do
          visit "/users/#{user.id}/edit"

          within("##{form_type}") do
            deal_with_dynamic_roles

            click_button 'Update User'
          end

          expect_result(user)
        end

      end
    end

    it 'should work with ActiveAttr' do
      visit '/email_forms/new'
      3.times{ click_link 'Add recipient' }
      remove_email_links.last.click

      email_inputs.last(2).each_with_index do |element, index|
        element.set("email#{index}@qwerty.com")
      end

      click_button 'Create Email form'

      expect(page).to have_content('Emails was sent to email0@qwerty.com, email1@qwerty.com')
    end

    it 'should not fail when remove link clicked but dynamic fields are not exists' do
      visit "/users/#{user.id}/edit_without_fields"

      click_link 'Remove without fields'
      click_button 'Update without fields'
      expect(page).to have_button('Update User')
    end

    it 'should add fields with clean text' do
      visit "/users/#{user.id}/edit_with_clean_text"
      within('.clean-text') do
        click_link 'Add role'
        expect(page).to have_content(Array.new(4, 'clean text').push('Add role').join(' '))
      end
    end

    it 'should remove fields with clean text' do
      visit "/users/#{user.id}/edit_with_clean_text"
      within('.clean-text-with-remove-link') do
        remove_role_links.last.click
        expect(page).to have_content(Array.new(2, 'clean text Remove role').push('Add role').join(' '))
      end
    end

    it 'should deal with turbolinks' do
      visit "/users/#{user.id}/edit_without_fields"
      click_link 'Edit'

      within('#form_for') do
        expect{click_link 'Add role'}.to change{remove_role_links.size}.from(3).to(4)
      end

    end

    it 'should trigger add event' do
      visit "/users/#{user.id}/events"

      click_link('Add role')
      expect(page).to have_selector(
        '#event_catcher', text: %Q(
          dynamic-fields:before-add-into : fields_container
          dynamic-fields:after-add : role_name
          dynamic-fields:after-add : remove_link
          dynamic-fields:after-add-into : fields_container
        ).gsub(/\s{2,}/, ' ').strip
      )
    end

    it 'should trigger remove event' do
      visit "/users/#{user.id}/events"

      all('a', text: 'Remove role').last.click
      expect(page).to have_selector(
        '#event_catcher', text: %Q(
          dynamic-fields:before-remove-from : fields_container
          dynamic-fields:before-remove : role_name
          dynamic-fields:before-remove : remove_link
          dynamic-fields:before-remove : id
          dynamic-fields:after-remove-from : fields_container
        ).gsub(/\s{2,}/, ' ').strip
      )
    end

  end
end
