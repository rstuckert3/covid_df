# Autor: Rodrigo Stuckert
# Data: 2020-06-23


# Esse código foi feito para analisar os casos da covid no Distrito Federal.
# Link para a página de extração: https://covid19.ssp.df.gov.br/extensions/covid19/covid19.html#/
# Dados do dia 2020-06-23 12h


# Pacotes:
library(dplyr)
library(lubridate) # Manipular datas


# Puxa o arquivo
arquivo <- "dados-abertos.csv"
link <- "https://covid19.ssp.df.gov.br/resources/dados/dados-abertos.csv"

# Importa os dados. 
# a saber, a função fread, do pacote data.table, é a mais recomendada para importação em 2020.
df <- data.table::fread(link, encoding = "UTF-8", 
                        col.names = c("id", "Data", "DataCadastro", "Sexo",
                                      "FaixaEtaria", "RA", "UF", "EstadoSaude",
                                      "Pneumopatia", "Nefropatia", "DHematologica",
                                      "DistMetabolico", "Imunopressao", "Obesidade",
                                      "Outros", "Cardiovasculopatia"),
                        colClasses = list(factor=4:7) # Colunas 4 a 8 (Sexo até UF) como factor
)

# Verifica a importação do arquivo
str(df) # Estrutura
head(df) # Início
tail(df) # Fim


# Bota os valores das comorbidades como binários (Apresenta = 1, não apresenta / NA = 0)
# EXPLICAÇÃO: de início, pessoas com alguma comorbidade recebiam "Sim"
# para aquelas que apresentassem, e "Não" para todas as demais, enquanto
# que quem não apresentasse nenhuma aparecia como NA para todas.
# Após determinada data, o GDF passou a apenas a categorizar aqueles que
# apresentassem alguma coisa.
df <- df %>% 
  mutate(Pneumopatia = ifelse(Pneumopatia == "Sim", 1, 0), 
         Nefropatia = ifelse(Nefropatia == "Sim", 1, 0),
         DHematologica = ifelse(DHematologica == "Sim", 1, 0),
         DistMetabolico = ifelse(DistMetabolico == "Sim", 1, 0),
         Imunopressao = ifelse(Imunopressao == "Sim", 1, 0),
         Obesidade = ifelse(Obesidade == "Sim", 1, 0),
         Outros = ifelse(Outros == "Sim", 1, 0),
         Cardiovasculopatia = ifelse(Cardiovasculopatia == "Sim", 1, 0)
  )


# Corrige a coluna das datas de entrada e cria a variável "Tem comorbidade?"
df <- df %>%
  mutate(DataCadastro = as.Date(DataCadastro, format = '%d/%m/%Y'),
         Comorbidade = Pneumopatia + Nefropatia + DHematologica + DistMetabolico + Imunopressao + Outros + Cardiovasculopatia,
         Comorbidade = ifelse(Comorbidade == 0, 0, 1))

# Verificando
class(df$DataCadastro)
head(df$DataCadastro)

# Cria a variável "Status", que mostra se a pessoa está recuperada,
# se foi a óbito, ou se é um caso ativo.
df <- df %>% 
  mutate(Status = ifelse(EstadoSaude %in% c("Leve", "Moderado", "Grave", "Não Informado"),
                         "Ativo", EstadoSaude))
table(df$Status)


# Backup
df2 <- df

# Pega a data de extração dos dados e descarta sua coluna (pois constante)
extraction_date <- df$Data[1]
df <- df %>%
  select(-c("Data"))
