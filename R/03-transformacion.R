# FUNCION PARA ESTIMAR BOX COX
estimar_boxcox <- function(y, indice_atipico = 100) {
  
  # Verificar datos
  y <- as.numeric(y)
  
  if (any(!is.finite(y))) {
    stop("La serie contiene valores faltantes o no finitos.")
  }
  
  if (indice_atipico < 1 || indice_atipico > length(y)) {
    stop("El índice del dato atípico está fuera del rango de la serie.")
  }
  
  # Desplazamiento para garantizar valores positivos
  desplazamiento <- if (min(y) <= 0) {
    1 - min(y)
  } else {
    0
  }
  
  y_positiva <- y + desplazamiento
  
  # Excluir el mes 100 únicamente para estimar lambda
  indices <- setdiff(seq_along(y), indice_atipico)
  
  lambda <- forecast::BoxCox.lambda(
    stats::ts(y_positiva[indices], frequency = 12),
    method = "guerrero"
  )
  
  # Aplicar transformaciones a la serie completa
  serie_bc <- forecast::BoxCox(y_positiva, lambda)
  
  serie_log <- log(y_positiva)
  
  # Comparar varianzas por mes del año
  comparar_varianza <- function(x) {
    
    grupos <- split(
      as.numeric(x),
      stats::cycle(stats::ts(x, frequency = 12))
    )
    
    varianzas <- sapply(grupos, stats::var, na.rm = TRUE)
    
    data.frame(
      varianza_media = mean(varianzas, na.rm = TRUE),
      cv_varianzas = stats::sd(varianzas, na.rm = TRUE) /
        mean(varianzas, na.rm = TRUE)
    )
  }
  
  comparacion <- rbind(
    cbind(
      transformacion = "Box-Cox",
      comparar_varianza(serie_bc)
    ),
    cbind(
      transformacion = "Logaritmo",
      comparar_varianza(serie_log)
    )
  )
  
  return(list(
    lambda = lambda,
    desplazamiento = desplazamiento,
    serie_bc = serie_bc,
    serie_log = serie_log,
    comparacion = comparacion
  ))
}


# Intervalo de confianza al 95 % para lambda (verosimilitud perfilada)
# La rejilla va redondeada a 2 decimales para que el 0 sea exactamente 0
ic_lambda <- function(y, g = round(seq(-1.5, 1.5, 0.05), 2)) {
  y <- ts(y, frequency = 12); n <- length(y); t <- seq_len(n); m <- factor(cycle(y))
  ll <- sapply(g, function(l) {
    z <- if (abs(l) < 1e-8) log(y) else (y^l - 1) / l
    -n / 2 * log(sum(resid(lm(z ~ t + m))^2) / n) + (l - 1) * sum(log(y))
  })
  ok <- g[ll >= max(ll) - qchisq(0.95, 1) / 2]
  c(lambda = g[which.max(ll)], inf = min(ok), sup = max(ok))
}

# Criterio de la Clase 16
aplicar_criterio <- function(lambda_hat, inf, sup) {
  if (inf <= 1   && sup >= 1)   return(1)    # sin transformación
  if (inf <= 0.5 && sup >= 0.5) return(0.5)  # raíz cuadrada
  if (inf <= 0   && sup >= 0)   return(0)    # logaritmo
  lambda_hat                                  # Box-Cox con lambda estimado
}

