require "application_system_test_case"

class JornadacitahorariasTest < ApplicationSystemTestCase
  setup do
    @jornadacitahoraria = jornadacitahorarias(:one)
  end

  test "visiting the index" do
    visit jornadacitahorarias_url
    assert_selector "h1", text: "Jornadacitahorarias"
  end

  test "creating a Jornadacitahoraria" do
    visit jornadacitahorarias_url
    click_on "New Jornadacitahoraria"

    fill_in "Cierre", with: @jornadacitahoraria.cierre
    fill_in "Duracion franja horaria", with: @jornadacitahoraria.duracion_franja_horaria
    fill_in "Escuelaperiodo", with: @jornadacitahoraria.escuelaperiodo_id
    fill_in "Inicio", with: @jornadacitahoraria.inicio
    fill_in "Max grados", with: @jornadacitahoraria.max_grados
    click_on "Create Jornadacitahoraria"

    assert_text "Jornadacitahoraria was successfully created"
    click_on "Back"
  end

  test "updating a Jornadacitahoraria" do
    visit jornadacitahorarias_url
    click_on "Edit", match: :first

    fill_in "Cierre", with: @jornadacitahoraria.cierre
    fill_in "Duracion franja horaria", with: @jornadacitahoraria.duracion_franja_horaria
    fill_in "Escuelaperiodo", with: @jornadacitahoraria.escuelaperiodo_id
    fill_in "Inicio", with: @jornadacitahoraria.inicio
    fill_in "Max grados", with: @jornadacitahoraria.max_grados
    click_on "Update Jornadacitahoraria"

    assert_text "Jornadacitahoraria was successfully updated"
    click_on "Back"
  end

  test "destroying a Jornadacitahoraria" do
    visit jornadacitahorarias_url
    page.accept_confirm do
      click_on "Destroy", match: :first
    end

    assert_text "Jornadacitahoraria was successfully destroyed"
  end
end
