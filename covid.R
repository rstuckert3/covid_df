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

df <- data.table::fread(link, encoding = "UTF-8", 
                        col.names = c("id", "Data", "DataCadastro", "Sexo",
                                      "FaixaEtaria", "RA", "UF", "EstadoSaude",
                                      "Pneumopatia", "Nefropatia", "DHematologica",
                                      "DistMetabolico", "Imunopressao", "Obesidade",
                                      "Outros", "Cardiovasculopatia")
)


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


# Verifica a importação do arquivo
str(df) # Estrutura
head(df) # Início
tail(df) # Fim
class(df$DataCadastro) # Classe da coluna data


# Corrige a coluna das datas de entrada
df <- df %>%
  mutate(DataCadastro = as.Date(DataCadastro, format = '%d/%m/%Y'))

# Verificando
class(df$DataCadastro)
head(df$DataCadastro)

# Cria a variável Comorbidade, que mostra se a pessoa tem ou não alguma comorbidade.
df <- df %>% mutate(Comorbidade = Pneumopatia + Nefropatia + DHematologica + DistMetabolico + Imunopressao + Outros + Cardiovasculopatia)
df <- df %>% mutate(Comorbidade = ifelse(Comorbidade == 0, 0, 1))

# Backup
df2 <- df


# [NÃO TA INDO] Cria a variável "Status", que mostra se a pessoa está recuperada,
# se foi a óbito, ou se é um caso ativo.
#df2 <- df2 %>% mutate(Status = EstadoSaude)
#df2 <- df2 %>% 
#  mutate(Status = replace(Status, Status != c("Recuperado", "Óbito"), "Ativo"))
#table(df2$Status)



# Cria a variável Status, que aponta se a observação é de um caso ativo
# (leve, moderado, grave ou Não Informado), ou um paciente recuperado ou
# que foi a óbito.
table(df$EstadoSaude)
df <- df %>% 
  mutate(Status = EstadoSaude)

df <- df %>% mutate(Status = if(Status == "Leve" | Status == "Moderado" | Status == "Grave" | Status == "Não Informado"){
    Status = "Ativo"} else {
      Status = Status}
    )



# Número de casos de obesidade no dataframe
sum(df$Obesidade)

