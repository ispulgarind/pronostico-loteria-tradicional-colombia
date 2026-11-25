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

dividir_datos <- function(obs, r = 25, h_max = 6) {
  obs <- obs |>
    tibble::as_tibble() |>
    dplyr::arrange(fecha) |>
    tsibble::as_tsibble(index = fecha)
  N <- nrow(obs)
  
  # Primer origen: deja r orígenes y h_max meses por pronosticar al final.
  # Con N = 174, r = 25 y h_max = 6 da t1 = 144 (diciembre de 2023).
  t1 <- N - (r - 1) - h_max
  stopifnot(t1 > 36)
  
  list(
    serie        = obs,
    entren       = dplyr::slice_head(obs, n = t1),   # para decidir: λ, d, D, modelo
    t1           = t1,
    t1_mes       = obs$fecha[t1],
    origenes     = t1:(t1 + r - 1),                  # posiciones de los orígenes
    origenes_mes = obs$fecha[t1:(t1 + r - 1)],
    h_max        = h_max
  )
}

datos_origen <- function(div, k, h) {
  T_k <- div$origenes[k]
  list(
    entren = dplyr::slice_head(div$serie, n = T_k),                    # lo que el modelo puede ver
    futuro = dplyr::slice(div$serie, (T_k + 1):(T_k + h)),             # meses a pronosticar
    acumulado_real = sum(div$serie$ventas_mill[(T_k + 1):(T_k + h)])   # A_h(T) observado
  )
}
