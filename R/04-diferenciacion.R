# FUNCION PARA DIFERENCIAR SERIE
diferenciar_serie <- function(datos, D = 1, d = 1, frecuencia = 12) {
  y <- datos$y
  if (D > 0) y <- diff(y, lag = frecuencia, differences = D)
  if (d > 0) y <- diff(y, differences = d)
  
  # Cada diferencia "gasta" las primeras observaciones
  perdidas <- length(datos$y) - length(y)
  
  resultado <- tibble::tibble(
    t = seq_along(y),
    fecha = datos$fecha[(perdidas + 1):length(datos$y)],
    y = y
  )
  attr(resultado, "frecuencia") <- attr(datos, "frecuencia")
  attr(resultado, "fuente") <- attr(datos, "fuente")
  attr(resultado, "unidad") <- paste(attr(datos, "unidad"), "diferenciada")
  resultado
}


# FUNCION PARA CREAR ETAPAS EN LA DIFERENCIACION
crear_etapas <- function(datos) {
  list(
    "Original"                          = datos,
    "Estacional (D=1)"                  = diferenciar_serie(datos, D = 1, d = 0),
    "Estacional + ordinaria (D=1, d=1)" = diferenciar_serie(datos, D = 1, d = 1)
  )
}


# TABLA COMPARATIVA DE DIFERENCIACION
# Compara la varianza y la ACF del primer rezago en cada etapa.
tabla_diferenciacion <- function(lista_series) {
  
  if (is.null(names(lista_series)) || any(names(lista_series) == "")) {
    stop("La lista debe tener nombres para identificar cada serie.")
  }
  
  do.call(rbind, lapply(names(lista_series), function(nombre) {
    
    etapas <- crear_etapas(lista_series[[nombre]])
    
    do.call(rbind, lapply(names(etapas), function(etapa) {
      
      y <- etapas[[etapa]]$y
      
      data.frame(
        serie = nombre,
        etapa = etapa,
        varianza = stats::var(y),
        ACF_rezago_1 = as.numeric(
          stats::acf(y, lag.max = 1, plot = FALSE)$acf[2]
        )
      )
    }))
  }))
}

# Panel completo: serie + ACF + PACF 
panel_serie_completo <- function(datos, titulo, m = 24) {
  grafico <- graficar_serie(datos, titulo)
  resultado_cor <- graficar_correlaciones(datos$y, m = m)
  panel_diagnostico(grafico, resultado_cor)
}

# Dickey-Fuller
prueba_df <- function(y, tipo, rezagos = 0, seleccion = "Fixed") {
  prueba <- urca::ur.df(y, type = tipo, lags = rezagos, selectlags = seleccion)
  tau <- c(none = "tau1", drift = "tau2", trend = "tau3")[[tipo]]
  list(
    estadistico = prueba@teststat[1, tau],
    critico     = prueba@cval[tau, "5pct"],
    rezagos     = prueba@lags
  )
}


# H0: hay raíz unitaria. Se rechaza H0 cuando el estadístico es MENOR
diagnostico_df <- function(y, tipo, max_rezagos = 12) {
  df  <- prueba_df(y, tipo, rezagos = 0)
  adf <- prueba_df(y, tipo, rezagos = max_rezagos, seleccion = "AIC")
  data.frame(
    tipo        = tipo,
    DF_tau      = df$estadistico,
    DF_crit     = df$critico,
    ADF_tau     = adf$estadistico,
    ADF_crit    = adf$critico,
    ADF_rezagos = adf$rezagos,
    DF_rechaza  = df$estadistico  < df$critico,
    ADF_rechaza = adf$estadistico < adf$critico
  )
}




