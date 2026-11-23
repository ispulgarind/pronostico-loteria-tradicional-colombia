# FUNCION PARA IMPUTAR, INTERPOLAR 2020
imputar_2020 <- function(df, col, meses = 3:8) {
  df  <- df[order(df$anio, df$mes), ]
  idx <- which(df$anio == 2020 & df$mes %in% meses)
  
  if (length(idx) == 0) return(df)       # lotería sin datos en esos meses
  
  cat("Valores originales de", col, "en 2020, meses", min(meses), "a",
      max(meses), ":", round(df[[col]][idx], 1), "\n")
  
  y <- df[[col]]
  y[idx] <- NA
  
  y_ts <- ts(y, frequency = 12, start = c(df$anio[1], df$mes[1]))
  df[[col]] <- as.numeric(na.interp(y_ts))
  df
}
