library(dplyr)
library(lubridate) # Manipular datas
library(ggplot2)
library(ggrepel) # Labels sem amontoar uma na outra.
library(sf) # Geoespacial

# Gifs
library(gganimate)
library(hrbrthemes)
library(transformr) # Para o animate de um objeto sf
library(gifski) # Para que o gganimate crie gifs, e não arquivos png


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

# Remove informações não utilizadas.
df <- df %>%
  dplyr::filter(df$UF == "DISTRITO FEDERAL") %>%
  select(-c(2, 3, 5, 6, 8:15))



##### FUNÇÕES #####



generate_days_RA_df <- function(first_day, last_day){
  # Cria um dataframe com as RAs repetidas por dia.
  
  # first_day, last_day = início e fim.
  
  first_day <- as.Date(first_day)
  last_day <- as.Date(last_day)
  
  # Nomes das RAs (sem Entorno, Sistema Penintenciário e Outros Estados)
  nomes_RAs <-  c("Águas Claras", "Arniqueira", "Brazlândia", "Candangolândia",
                 "Ceilândia", "Cruzeiro", "Fercal", "Gama", "Guará", "Itapoã",
                 "Jardim Botânico", "Lago Norte", "Lago Sul", "Núcleo Bandeirante",
                 "Paranoá", "Park Way", "Planaltina", "Plano Piloto", "Pôr do Sol",
                 "Recanto das Emas", "Riacho Fundo", "Riacho Fundo II", "Samambaia",
                 "Santa Maria", "São Sebastião", "SCIA", "SIA", "Sobradinho",
                 "Sobradinho II", "Sudoeste/Octogonal", "Taguatinga", "Varjão",
                 "Vicente Pires")
  
  # Nº de dias
  num_days <- length(seq(first_day, last_day, by = "days"))
  
  # Vetor com os dias
  DataCadastro <- seq(first_day, last_day, by = "days") %>%
    rep(times = length(nomes_RAs)) %>%
    sort()
  
  # Todas as RAs, repetidas em ordem alfabética
  RA <- rep(nomes_RAs, times = num_days)
  
  # Junta os dois vetores
  return(cbind.data.frame(DataCadastro, RA))
}


generate_cases_df <- function(days_RA_df, cases_df, option = "confirmacao"){
  # Faz o merge do df com os casos, e o df com as datas completas.
  
  # days_RA_df = df com todos os dias para todas as RAs.
  # cases_df = df com os casos
  # option = se os casos serão considerados pela data de confirmação
    # ou pela data dos primeiros sintomas (opções: "confirmacao", "sintomas")
  
  # Condição guard.
  if (option != "confirmacao" & option != "sintomas" ){
    print("Erro! A opção deverá ser ou 'confirmacao', ou 'sintomas'.")
    return(NULL)
  }
  
  # Se for por data dos sintomas, remove os casos em que há erro
  # (ie, a pessoa teve sintomas só APÓS ser confirmada)
  if (option == "sintomas"){
    cases_df <- cases_df[cases_df$DataPrimeirosintomas <= cases_df$DataCadastro, ]
    cases_df <- cases_df %>%
      select(-c(DataCadastro)) 
    
   names(cases_df)[names(cases_df) == "DataPrimeirosintomas"] <- "DataCadastro"
  }
  
  # Junta os casos por dia
  gDataRA <- cases_df %>%
    group_by(DataCadastro, RA) %>%
    summarise(casos = n())
  
  # Faz o join dos dois dataframes.
  result_df <- left_join(days_RA_df, gDataRA, by = c("DataCadastro", "RA")) %>%
    mutate(casos = ifelse(is.na(casos) == TRUE, 0, casos))
  
  return(result_df)
}


generate_moving_window <- function(df, moving_window){
  ## Cria uma janela móvel dos casos de uma variável.
  
  # df = dataframe
  # moving_window = janela móvel (em dias)
  
  df_ma <- df %>% 
    group_by(RA) %>% 
    mutate(roll.sum = c(casos[1:(moving_window-1)], zoo::rollapply(casos, moving_window, sum)))
  
  return(df_ma)
}

generate_geo_df <- function(file_address = "datasets/georref/Regiões Administrativas.shp"){
  # Gera o dataframe com as coordenadas geoespaciais das RAs.
  
  # file_address = caminho com o arquivo .shp
  
  # Pega os dados geoespaciais
  df_RegioesAdm <- st_read(file_address)
  colnames(df_RegioesAdm)[2] <- "RA"
  df_RegioesAdm <- df_RegioesAdm[,c(2, 8)] # Mantém apenas as colunas de interesse
  
  return(df_RegioesAdm)
}

generate_df <- function(df, first_day, last_day, moving_window = 14,
                        option = "sintomas", endereco_geo = "datasets/georref/Regiões Administrativas.shp"){
  # Gera o dataframe com a janela móvel pros casos desejados.
  
  # df = dataframe original
  # fist_day, last_day = primeiro e último dias
  # moving_window = nº de dias da janela móvel
  # option = se contar pela data dos primeiros "sintomas", ou pela "confirmacao"
  # endereco_geo = endereço do arquivo com as coordenadas geográficas.
  
  my_df <- df
  df_days_RA <- generate_days_RA_df(first_day, last_day) # df de dias e RAs
  df_days_RA_cases <- generate_cases_df(df_days_RA, my_df, option) # acrescenta os casos
  df_ma <- generate_moving_window(df_days_RA_cases, moving_window) # faz a janela móvel
  
  # DFs finais
  my_df <- df_ma
  df_geo <- generate_geo_df(file_address = endereco_geo) # Coordenadas geoespaciais
  
  # Dá o left join dos dataframes
  df_final <- left_join(df_ma, df_geo, by = "RA")
  
  return(df_final)
}

generate_title <- function(moving_window = 14){
  # Gera o título do gráfico, de acordo os inputs.
  
  # moving_window = janela móvel dos dados
  # option = se os dados foram por data de confirmação, ou data dos primeiros sintomas.
  
  titulo = "Casos de covid no DF por "
  
  if(moving_window == 14){
    titulo = stringr::str_c(titulo, "quinzena móvel")
  } else {
    titulo = stringr::str_c(titulo, "semana móvel")
  }
  return(titulo)
}

generate_caption <- function(option = "sintomas"){
  # Gera a caption (mensagem no canto inferior) do gráfico
  
  # option = se os dados foram por data de confirmação, ou data dos primeiros sintomas.
  
  if(option == "sintomas"){
    my_caption = "Nota: por data dos primeiros sintomas\nFonte: SESDF / SSP-DF \nElaboração: Rodrigo Stuckert"
  } else {
    my_caption = "Fonte: SESDF / SSP-DF \nElaboração: Rodrigo Stuckert"
  }
  
  return(my_caption)
}



##### INPUTS #####





# Dados de interesse
first_day <- as.Date("2020-02-01")
last_day <- as.Date(last_update, format = '%d/%m/%Y')  
opcao <- "sintomas"
moving_window <- 14 # Janela móvel de casos
file_path <- "datasets/georref/Regiões Administrativas.shp" # Endereço dos dados geoespaciais

# Gera o dataframe com os casos móveis
df_final <- generate_df(df, first_day, last_day, moving_window = 14,
                     option = "sintomas", endereco_geo = file_path)

# Cria o título e a caption do gráfico
my_title <- generate_title(moving_window)
my_caption <- generate_caption(option = opcao)



#### PARTE GRÁFICA ###


# Para o gráfico não ter marcas nos eixos
no_axis <- theme(axis.title=element_blank(),
                 axis.text=element_blank(),
                 axis.ticks=element_blank())


# Gif
my_gif <- df_final %>%
  filter(DataCadastro == as.Date("2020-07-31")) %>% # Datas a partir desse dia
  ggplot((aes(geometry = geometry, fill = roll.sum))) +
  geom_sf(size = 1L, stat = "sf") + # Coordenadas
  geom_sf_text(aes(label = RA), size = 2.75) + # Nome das RAs
  scale_fill_distiller(palette = "OrRd", direction = 1) + # Paleta de cores
  labs(title = my_title,
       subtitle='{frame_time}',
       fill = "Casos",
       caption = my_caption) +
  theme_minimal() + # Fundo branco
  theme(plot.caption = element_text(hjust = 0)) + # Caption na esquerda
  no_axis
  #+
  # GGanimate agora:
  transition_time(DataCadastro) +
  ease_aes('linear')

animate(my_gif, renderer = gifski_renderer(), fps = 13, 
        width = 600, height = 450)


my_gif <- df_final %>%
  filter(DataCadastro == as.Date("2020-07-31")) %>% # Datas a partir desse dia
  ggplot((aes(geometry = geometry, fill = roll.sum))) +
  geom_sf(size = 1L, stat = "sf") + # Coordenadas
  geom_sf_text(aes(label = RA), check_overlap = TRUE, size = 2.75) + # Nome das RAs
  #ggrepel::geom_label_repel(aes(label = RA, geometry = geometry),
  #                          stat = "sf_coordinates",  min.segment.length = 0) +
  scale_fill_distiller(palette = "OrRd", direction = 1) + # Paleta de cores
  labs(title = my_title,
       subtitle='{frame_time}',
       fill = "Casos",
       caption = my_caption) +
  theme_minimal() + # Fundo branco
  theme(plot.caption = element_text(hjust = 0)) + # Caption na esquerda
  no_axis # +

my_gif  

# GGanimate agora:
  transition_time(DataCadastro) +
  ease_aes('linear')

animate(my_gif, renderer = gifski_renderer(), fps = 13, 
        width = 600, height = 450)


my_gif