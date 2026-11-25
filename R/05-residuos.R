diagnosticar_modelo <- function(modelo_nombre, fits_list, serie_df) {
  f <- fits_list[[modelo_nombre]]
  stopifnot(!is.null(f))
  
  # Excluir las primeras 14 observaciones (d + 12*D + 1) para evitar el salto de inicialización
  n_init <- f$arma[6] + f$arma[5] * f$arma[7] + 1
  res    <- as.numeric(residuals(f))[-(1:n_init)]
  npar   <- sum(f$arma[1:4])
  
  datos_res <- data.frame(
    fecha = serie_df$fecha[-(1:n_init)],
    y     = res
  )
  attr(datos_res, "unidad") <- "escala Box-Cox"
  attr(datos_res, "fuente") <- paste("residuos de", modelo_nombre)
  
  # 1. Gráficos de residuos, ACF y PACF
  g_res     <- graficar_serie(datos_res, paste("Residuos -", modelo_nombre)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey50")
  cor_res   <- graficar_correlaciones(res, m = 24)
  panel_res <- panel_diagnostico(g_res, cor_res)
  
  # 2. QQ-plot y prueba Jarque-Bera
  g_qq <- ggplot(data.frame(res), aes(sample = res)) +
    stat_qq(color = "purple") +
    stat_qq_line() +
    labs(
      title = paste("QQ-plot de los residuos -", modelo_nombre),
      x = "Cuantiles teóricos",
      y = "Cuantiles de los residuos"
    ) +
    theme_minimal()
  
  jb <- jarque.bera.test(res)
  tab_jb <- data.frame(
    Prueba      = "Jarque-Bera",
    Estadístico = jb$statistic,
    gl          = jb$parameter,
    `Valor p`   = jb$p.value,
    Conclusión  = ifelse(jb$p.value > 0.05, "No se rechaza H0", "Se rechaza H0"),
    check.names = FALSE
  )
  
  # 3. Prueba Ljung-Box en rezagos 12 y 24
  lb12 <- Box.test(res, lag = 12, type = "Ljung-Box", fitdf = npar)
  lb24 <- Box.test(res, lag = 24, type = "Ljung-Box", fitdf = npar)
  
  tab_lb <- data.frame(
    Rezagos     = c(12, 24),
    Estadístico = c(lb12$statistic, lb24$statistic),
    gl          = c(lb12$parameter, lb24$parameter),
    `Valor p`   = c(lb12$p.value,   lb24$p.value),
    Conclusión  = ifelse(c(lb12$p.value, lb24$p.value) > 0.05,
                         "No se rechaza H0", "Se rechaza H0"),
    check.names = FALSE
  )
  
  list(
    panel_res = panel_res,
    g_qq      = g_qq,
    tab_jb    = tab_jb,
    tab_lb    = tab_lb
  )
}