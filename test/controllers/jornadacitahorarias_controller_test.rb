require 'test_helper'

class JornadacitahorariasControllerTest < ActionDispatch::IntegrationTest
  setup do
    @jornadacitahoraria = jornadacitahorarias(:one)
  end

  test "should get index" do
    get jornadacitahorarias_url
    assert_response :success
  end

  test "should get new" do
    get new_jornadacitahoraria_url
    assert_response :success
  end

  test "should create jornadacitahoraria" do
    assert_difference('Jornadacitahoraria.count') do
      post jornadacitahorarias_url, params: { jornadacitahoraria: { cierre: @jornadacitahoraria.cierre, duracion_franja_horaria: @jornadacitahoraria.duracion_franja_horaria, escuelaperiodo_id: @jornadacitahoraria.escuelaperiodo_id, inicio: @jornadacitahoraria.inicio, max_grados: @jornadacitahoraria.max_grados } }
    end

    assert_redirected_to jornadacitahoraria_url(Jornadacitahoraria.last)
  end

  test "should show jornadacitahoraria" do
    get jornadacitahoraria_url(@jornadacitahoraria)
    assert_response :success
  end

  test "should get edit" do
    get edit_jornadacitahoraria_url(@jornadacitahoraria)
    assert_response :success
  end

  test "should update jornadacitahoraria" do
    patch jornadacitahoraria_url(@jornadacitahoraria), params: { jornadacitahoraria: { cierre: @jornadacitahoraria.cierre, duracion_franja_horaria: @jornadacitahoraria.duracion_franja_horaria, escuelaperiodo_id: @jornadacitahoraria.escuelaperiodo_id, inicio: @jornadacitahoraria.inicio, max_grados: @jornadacitahoraria.max_grados } }
    assert_redirected_to jornadacitahoraria_url(@jornadacitahoraria)
  end

  test "should destroy jornadacitahoraria" do
    assert_difference('Jornadacitahoraria.count', -1) do
      delete jornadacitahoraria_url(@jornadacitahoraria)
    end

    assert_redirected_to jornadacitahorarias_url
  end
end
