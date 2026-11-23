#FUNCION GRAFICAR SERIE
graficar_serie <- function(datos, titulo) {
  
  ggplot2::ggplot(datos, ggplot2::aes(x = fecha, y = y)) +
    
    ggplot2::geom_line(color = "purple") +
    
    ggplot2::labs(
      title = titulo,
      x = "Fecha",
      y = paste0("Valor (", attr(datos, "unidad"), ")"),
      caption = paste0(
        "Fuente: ", attr(datos, "fuente"),
        " | Observaciones: ", length(datos$y)
      )
    ) +
    
    ggplot2::theme_minimal()
}


#FUNCION CORRELOGRAMA Y PACF
graficar_correlaciones <- function(datos, m = 24) {
  
  if (!is.numeric(datos)) {
    stop("La serie debe ser numérica.")
  }
  
  if (any(is.na(datos))) {
    stop("La serie contiene valores faltantes.")
  }
  
  n <- length(datos)
  
  if (m < 1 || m >= n) {
    stop("El número de rezagos debe ser mayor que 0 y menor que n.")
  }
  
  # Calcular ACF y PACF con R
  acf_resultado <- stats::acf(datos, lag.max = m, plot = FALSE)
  pacf_resultado <- stats::pacf(datos, lag.max = m, plot = FALSE)
  
  # Extraer valores
  acf_valores <- as.numeric(acf_resultado$acf)[-1]
  pacf_valores <- as.numeric(pacf_resultado$acf)
  
  # Bandas de confianza
  banda <- 1.96 / sqrt(n)
  
  # Datos para los gráficos
  datos_acf <- data.frame(
    rezago = 1:m,
    valor = acf_valores
  )
  
  datos_pacf <- data.frame(
    rezago = 1:m,
    valor = pacf_valores
  )
  
  # Gráfico ACF
  grafico_acf <- ggplot2::ggplot(
    datos_acf,
    ggplot2::aes(x = rezago, y = valor)
  ) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::geom_hline(
      yintercept = c(-banda, banda),
      linetype = "dashed",
      color = "red"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(xend = rezago, y = 0, yend = valor),
      color = "purple"
    ) +
    ggplot2::labs(
      title = "ACF",
      x = "Rezago",
      y = "Autocorrelación"
    ) +
    ggplot2::theme_minimal()
  
  # Gráfico PACF
  grafico_pacf <- ggplot2::ggplot(
    datos_pacf,
    ggplot2::aes(x = rezago, y = valor)
  ) +
    ggplot2::geom_hline(yintercept = 0) +
    ggplot2::geom_hline(
      yintercept = c(-banda, banda),
      linetype = "dashed",
      color = "red"
    ) +
    ggplot2::geom_segment(
      ggplot2::aes(xend = rezago, y = 0, yend = valor),
      color = "purple"
    ) +
    ggplot2::labs(
      title = "PACF",
      x = "Rezago",
      y = "Autocorrelación parcial"
    ) +
    ggplot2::theme_minimal()
  
  # Unir gráficos
  panel <- patchwork::wrap_plots(
    grafico_acf,
    grafico_pacf,
    ncol = 1
  )
  
  return(
    list(
      acf = acf_valores,
      pacf = pacf_valores,
      banda = banda,
      grafico = panel
    )
  )
}

#PANEL DIAGNOSTICO
panel_diagnostico <- function(grafico_serie, resultado_cor) {
  
  grafico_acf <- resultado_cor$grafico[[1]]
  grafico_pacf <- resultado_cor$grafico[[2]]
  
  panel <- (
    grafico_serie |
      (grafico_acf / grafico_pacf)
  )
  
  return(panel)
}


# FUNCION PARA EL DIAGNOSTIVCO DE CADA LOTERIA
diagnostico_loteria <- function(archivo, nombre) {
  
  # Leer serie
  serie <- leer_serie(
    archivo,
    variable = "ventas",
    fuente = "Coljuegos",
    unidad = "pesos"
  )
  
  # Graficar serie
  grafico <- graficar_serie(
    serie,
    paste("Ventas", nombre)
  )
  
  # Calcular ACF y PACF
  resultado_cor <- graficar_correlaciones(
    serie$y,
    m = 24
  )
  
  # Panel de diagnóstico
  panel <- panel_diagnostico(
    grafico,
    resultado_cor
  )
  
  return(panel)
}