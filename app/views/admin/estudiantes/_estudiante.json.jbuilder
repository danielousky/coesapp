<<<<<<< HEAD
# ["ci", "nombres", "apellidos", "email", "telefono_habitacion", "telefono_movil", "password", "sexo", "created_at", "updated_at", "nacionalidad", "estado_civil", "fecha_nacimiento", "pais_nacimiento", "ciudad_nacimiento"] 
usuario = estudiante.usuario
attributes = usuario.attributes.values
# begin
# 	foto_perfil_value = main_app.url_for(usuario.foto_perfil) 
# rescue StandardError => e
# 	foto_perfil_value = ''
# end

# attributes << foto_perfil_value
=======
# ["ci", "nombres", "apellidos", "email", "telefono_habitacion", "telefono_movil", "password", "sexo", "created_at", "updated_at", "nacionalidad", "estado_civil", "fecha_nacimiento", "pais_nacimiento", "ciudad_nacimiento"] 
usuario = estudiante.usuario
attributes = usuario.attributes.values
# begin
# 	foto_perfil_value = main_app.url_for(usuario.foto_perfil) 
# rescue StandardError => e
# 	foto_perfil_value = ''
# end

# attributes << foto_perfil_value

attributes << estudiante.grados.map{|g| g.reglamento}.to_sentence
>>>>>>> 7050be81cac4498c00dca402ed6e2dcdaed2406e
json.array! attributes