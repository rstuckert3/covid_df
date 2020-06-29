# Autor: Rodrigo Stuckert
# Data: 2020-06-23


# Esse código foi feito para analisar os casos da covid no Distrito Federal.
# Link para a página de extração: https://covid19.ssp.df.gov.br/extensions/covid19/covid19.html#/



# Pacotes:
library(dplyr)
library(ggplot2)
library(readr) # Para garantir o encoding


# Internet:
#library(rvest)
#x <- "https://covid19.ssp.df.gov.br/resources/dados/dados-abertos.csv?param=[random]"
#pagina <- read_html(x)


# Puxa o arquivo
arquivo <- "dados-abertos.csv"
df <- read_delim(file = arquivo, delim = ";")
#df2 <- read.csv2(file = arquivo, as.is = !stringsAsFactors, na.strings = "NA") # Padrão brasileiro, mas sem encoding correto.

