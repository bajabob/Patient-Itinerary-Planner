Feature: Edit Appointment

  As a patient or doctor
  So I can edit an appointment
  I want to go to an edit appointment page and edit an existing appointment

Scenario: When an Appointment button is clicked, appointment page is rendered

  Given I am an authenticated user
  And I am on the Care Coordinator home page
  When I press on an appointment
  Then I should be on an appointment page

Scenario: When Edit Appointment button is clicked, edit appointment page is rendered

  Given I am an authenticated user
  And I am on the appointment page
  When I click on "Edit"
  Then I should be on the Update Appointment page

Scenario: When information is inputted into fields, and they are saved, then appointment is updated

  Given I am an authenticated user
  And I am on the Update Appointment page
  When appointment information is inputted
  And Update Appointment Info is clicked
  Then I should get a pop up
  And I should be on an appointment page
  
