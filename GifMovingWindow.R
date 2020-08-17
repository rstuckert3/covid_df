library(dplyr)
library(lubridate) # Manipular datas
library(ggplot2)

#file <- "https://covid19.ssp.df.gov.br/resources/dados/dados-abertos.csv"
file <- "datasets/dados-abertos.csv"
df <- data.table::fread(file, encoding = "UTF-8", 
                        col.names = c("Data", "DataCadastro", "Sexo",
                                      "FaixaEtaria", "RA", "UF", "Obito", "DataPrimeirosintomas",
                                      "Pneumopatia", "Nefropatia", "DHematologica",
                                      "DistMetabolico", "Imunopressao", "Obesidade",
                                      "Outros", "Cardiovasculopatia"),
                        colClasses = list(factor= c(3, 6)) # Colunas Sexo e UF como factors
)

# Análise da importação
str(df) # Estrutura
head(df) # Início

# Pega a data do dataset
last_update <- df$Data[1]

# Remove a coluna com a data da última atualização daqueles dados e corrige o formato das demais datas.
df <- df %>%
  select(-c("Data")) %>%
  mutate(DataCadastro = as.Date(DataCadastro, format = '%d/%m/%Y'),
         DataPrimeirosintomas = as.Date(DataPrimeirosintomas, format = '%d/%m/%Y'))


# Corrige os nomes das faixas etárias e torna a variável factor.
df <- df %>%
  mutate(FaixaEtaria = ifelse(FaixaEtaria == "<= 19 anos", "0 a 19 anos", FaixaEtaria),
         FaixaEtaria = ifelse(FaixaEtaria == ">= 60 anos", "60+ anos", FaixaEtaria),
         FaixaEtaria = as.factor(FaixaEtaria))

# Bota os valores das comorbidades como binários (Apresenta = 1, não apresenta / NA = 0) e converte para inteiro.
# OBS: Margin = 2: aplica a função "FUN" às COLUNAS
df[, c(6, 8:15)] <- df[, c(6, 8:15)] %>%
  apply(MARGIN = 2, FUN = function(x) ifelse(x == "Sim", 1, 0)) %>% # Função lambda
  apply(MARGIN = 2, FUN = as.integer)

# Cria a variável "Tem comorbidade?", como número inteiro.
df <- df %>%  
  mutate(Comorbidade = as.integer(case_when(Pneumopatia + Nefropatia + DHematologica + DistMetabolico + Imunopressao + Outros + Cardiovasculopatia > 0 ~ 1, TRUE ~ 0)))




create_df <- function(regioes_adm, variable, first_day, last_day){
  # Cria um dataframe com a contagem de casos para as RAs especificadas.
  
  # regioes_adm = RAs
  # variable = variável de interesse
  # first_day, last_day = início e fim.
  
  nomesRAs <-  c("Águas Claras", "Arniqueira", "Brazlândia", "Candangolândia",
                 "Ceilândia", "Cruzeiro", "Fercal", "Gama", "Guará", "Itapoã",
                 "Jardim Botânico", "Lago Norte", "Lago Sul", "Núcleo Bandeirante",
                 "Paranoá", "Park Way", "Planaltina", "Plano Piloto", "Pôr do Sol",
                 "Recanto das Emas", "Riacho Fundo", "Riacho Fundo II", "Samambaia",
                 "Santa Maria", "São Sebastião", "SCIA", "SIA", "Sobradinho",
                 "Sobradinho II", "Sudoeste/Octogonal", "Taguatinga", "Varjão",
                 "Vicente Pires")
  
  
  return(NULL)
  
  
}
  
# Cria o agrupamento por data e RA
gDataRA <- df %>%
  group_by(DataCadastro, RA) %>%
  summarise(casos = n())

# Pega as RAs
nomesRAs <- unique(df$RA)
nomesRAs <- nomesRAs[!nomesRAs %in% c("Outros Estados", "Entorno DF",
                                "Sistema Penitenciário", "Não Informado")] %>%
  sort()


# Gerando o nosso dataframe de interesse.
first_day <- as.Date("2020-03-01")
last_day <- as.Date(last_update, format = '%d/%m/%Y')  
num_days <- length(seq(first_day, last_day, by = "days")) # Nº de dias

# Vetor com todos os dias da amostra
DataCadastro <- seq(first_day, last_day, by = "days") %>%
  rep(times = length(nomesRAs))%>%
  sort()

# Todas as RAs, repetidas em ordem alfabética
RA <- rep(nomesRAs, times = num_days)

# Junta os dois vetores, e dá o join com o df com os dados dos casos
df_complete <- cbind.data.frame(DataCadastro, RA) %>%
 left_join(gDataRA, by = c("DataCadastro", "RA")) %>%
 mutate(casos = ifelse(is.na(casos) == TRUE, 0, casos))



# Janela móvel
moving_window <- 14

df_ma <- df_complete %>% 
  group_by(RA) %>% 
  mutate(roll.sum = c(casos[1:(moving_window-1)], zoo::rollapply(casos, moving_window, sum)))



# Geoespaciais
library(sf)
library(ggplot2)


RegioesAdm <- st_read("datasets/georref/Regiões Administrativas.shp")
colnames(RegioesAdm)[2] <- "RA"

RegioesAdm <- RegioesAdm[,c(2, 8)]


# O df "Regioes_bkp" encontra-se no arquivo RegAd.R
df_final <- left_join(df_ma, RegioesAdm, by = "RA")



# Para o gráfico não ter marcas nos eixos
no_axis <- theme(axis.title=element_blank(),
                 axis.text=element_blank(),
                 axis.ticks=element_blank())



df_final %>%
 filter(DataCadastro == as.Date("2020-08-06")) %>%
 ggplot((aes(geometry = geometry, fill = roll.sum))) +
  geom_sf(size = 1L, stat = "sf") +
  geom_sf_text(aes(label = RA), size = 2L) +
  scale_fill_distiller(palette = "OrRd", direction = 1) +
  labs(title = "Casos de covid-19 no Distrito Federal por semana móvel",
       fill = "Casos") +
  theme_minimal() +
  no_axis

rm(df, df_complete, df_ma, df_more_than_complete,
   all_days, all_RAs, gDataRA)



library(gganimate)
library(hrbrthemes)
library(transformr) # Para o animate de um objeto sf
library(gifski) # Para que o gganimate crie gifs, e não arquivos png


# Gif
my_gif <- df_final %>%
  filter(DataCadastro >= as.Date("2020-07-12")) %>%
  ggplot((aes(geometry = geometry, fill = roll.sum))) +
  geom_sf(size = 1L, stat = "sf") +
  geom_sf_text(aes(label = RA), size = 2L) +
  scale_fill_distiller(palette = "OrRd", direction = 1) +
  labs(title = "Casos de covid-19 no Distrito Federal por semana móvel",
       subtitle='{frame_time}',
       fill = "Casos",
       caption ='Fonte: SESDF / SSP-DF \nElaboração: Rodrigo Stuckert') +
  theme_minimal() +
  no_axis +
  # GGanimate agora:
  transition_time(DataCadastro) +
  ease_aes('linear')

animate(my_gif, renderer = gifski_renderer(), fps = 10)




# SEM FILTRO DE DATA
my_gif <- df_final %>%
  ggplot((aes(geometry = geometry, fill = roll.sum))) +
  geom_sf(size = 1L, stat = "sf") +
  scale_fill_distiller(palette = "OrRd", direction = 1) +
  labs(title = "Casos de covid-19 no Distrito Federal por semana móvel",
       subtitle='{frame_time}',
       fill = "Casos",
       caption ='Fonte: SESDF / SSP-DF \nElaboração: Rodrigo Stuckert') +
  theme_minimal() +
  no_axis +
  # GGanimate agora:
  transition_time(DataCadastro) +
  ease_aes('linear')

animate(my_gif, fps = 15) #, width = 1200, height = 900)