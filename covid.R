# Autor: Rodrigo Stuckert
# Data: 2020-06-23


# Esse código foi feito para analisar os casos da covid no Distrito Federal.
# Link para a página de extração: https://covid19.ssp.df.gov.br/extensions/covid19/covid19.html#/
# Dados do dia 2020-06-23 12h


# Pacotes:
library(dplyr)
library(lubridate) # Manipular datas
library(forcats) # fct_reoder
library(ggplot2)
library(esquisse) # Interface pro ggplot2



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

# Pega a data de extração dos dados
extraction_date <- df$Data[1] %>%
  as.Date(format = '%d/%m/%Y')

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


# Remove a coluna com a data de extração, corrige a coluna das datas de entrada,
# e cria as variáveis "Tem comorbidade?" e "Estado ativo?"
df <- df %>%
  
  select(-c("Data")) %>%
  
  mutate(DataCadastro = as.Date(DataCadastro, format = '%d/%m/%Y'),
         Comorbidade = case_when(Pneumopatia + Nefropatia + DHematologica + DistMetabolico + Imunopressao + Outros + Cardiovasculopatia > 0 ~ 1, TRUE ~ 0)) %>%
  
  mutate(Status = ifelse(EstadoSaude %in% c("Leve", "Moderado", "Grave", "Não Informado"), 
                         "Ativo", EstadoSaude)) # Cria a variável "Status", que mostra se a pessoa está recuperada,se foi a óbito, ou se é um caso ativo.



# Transforma as idades em factor e as ordena.
str(df$FaixaEtaria)


# Verificando
class(df$DataCadastro)
head(df$DataCadastro)
table(df$Status) # Variável de estado do paciente

# Backup
df2 <- df



# Gera estatísticas agrupadas
grouped_by_RA <- df %>% 
  group_by(RA) %>%
  summarise(casos = n(),
            casos_ativos = sum(Status == "Ativo"),
            obitos = sum(Status == "Óbito"),
            mortalidade = obitos / casos,
            pct_comorbidade = sum(Comorbidade == 1) / casos,
            pct_mulheres = sum(Sexo == "Feminino")/casos,
            pct_homens = 1 - pct_mulheres
            )


grouped_by_Sexo <- df %>% 
  group_by(Sexo) %>%
  summarise(casos = n(),
            casos_ativos = sum(Status == "Ativo"),
            obitos = sum(Status == "Óbito"),
            mortalidade = obitos / casos,
            pct_comorbidade = sum(Comorbidade == 1) / casos
            )

grouped_by_FxEtaria <- df %>% 
  group_by(FaixaEtaria) %>%
  summarise(casos = n(),
            casos_ativos = sum(Status == "Ativo"),
            obitos = sum(Status == "Óbito"),
            pct_obitos = sum(Status == "Óbito") / sum(df$Status == "Óbito"),
            mortalidade = obitos / casos,
            pct_comorbidade = sum(Comorbidade == 1) / casos,
            pct_mulheres = sum(Sexo == "Feminino")/casos,
            pct_homens = 1 - pct_mulheres
            )

# Visualização gráfica.
#esquisser(data = df)

df %>%
 filter(!(UF %in% "")) %>%
 ggplot() +
 aes(x = EstadoSaude, fill = FaixaEtaria) +
 geom_bar(position = "fill") +
 scale_fill_viridis_d(option = "inferno") +
 theme_minimal()

df %>%
  filter(!(UF %in% "")) %>%
  ggplot() +
  aes(x = FaixaEtaria, fill = Sexo) +
  geom_bar() +
  scale_fill_hue() +
  theme_minimal() +
  facet_wrap(vars(RA))

#df <- df %>%
#  mutate(Comorbidade = as.factor(df$Comorbidade))

df %>%
  filter(!(UF %in% "")) %>%
  ggplot() +
  aes(x = FaixaEtaria, fill = Comorbidade) +
  geom_bar() +
  scale_fill_gradient() +
  theme_minimal() +
  facet_wrap(vars(RA))
