# json.extract! departamento, :id, :descripcion
# json.url departamento_url(departamento, format: :json)
json.array! [departamento.id, departamento.descripcion, departamento.asignaturas.count, departamento.inscripcionsecciones.del_periodo(current_periodo.id).count, departamento.secciones.del_periodo(current_periodo.id).count]