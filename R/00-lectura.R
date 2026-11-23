leer_serie <- function(x, fuente, unidad, variable = "ventas_mill") {
  
  datos <- read.csv(x)
  
  if (!all(c("anio", "mes", variable) %in% names(datos))) {
    stop("El CSV debe tener las columnas 'anio', 'mes' y la variable seleccionada.")
  }
  
  anio <- as.integer(datos$anio)
  mes <- as.integer(datos$mes)
  y <- as.numeric(datos[[variable]])
  
  fecha <- as.Date(sprintf("%04d-%02d-01", anio, mes))
  
  # Verificaciones
  if (any(is.na(fecha))) {
    stop("Hay fechas inválidas en el CSV.")
  }
  
  if (any(is.na(y))) {
    stop("La serie contiene valores faltantes o no numéricos.")
  }
  
  if (any(mes < 1 | mes > 12)) {
    stop("Los meses deben estar entre 1 y 12.")
  }
  
  if (length(y) < 2) {
    stop("Se necesitan al menos dos observaciones.")
  }
  
  if (any(diff(fecha) <= 0)) {
    stop("Las fechas deben estar en orden creciente y sin repetir.")
  }
  
  periodo <- anio * 12 + mes
  
  if (any(diff(periodo) != 1)) {
    stop("Las fechas no tienen una frecuencia mensual constante.")
  }
  
  resultado <- tibble::tibble(
    t = 1:length(y),
    fecha = fecha,
    y = y
  )
  
  attr(resultado, "frecuencia") <- "mensual"
  attr(resultado, "fuente") <- fuente
  attr(resultado, "unidad") <- unidad
  
  return(resultado)
}