library(dplyr)
library(lubridate) # Manipular datas
library(ggplot2)
library(ggrepel) # Labels sem amontoar uma na outra.
library(sf) # Geoespacial

# Gifs
library(gganimate) # Gifs
library(transformr) # Para o animate de um objeto sf
library(gifski) # Para que o gganimate crie gifs, e não arquivos png


#### TRATAMENTO DOS DADOS ####


file <- "https://covid19.ssp.df.gov.br/resources/dados/dados-abertos.csv"
#file <- "datasets/dados-abertos.csv"
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
    mutate(casos_moveis = c(casos[1:(moving_window-1)], zoo::rollapply(casos, moving_window, sum)))
  
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
  # option = se contar pela data dos primeiros "sintomas", ou pela "confirmacao" (aceita tb "cadastro")
  # endereco_geo = endereço do arquivo com as coordenadas geográficas.
  
  #Se a pessoa colocar o option como "cadastro", muda pra "confirmacao"
  if (option == "cadastro"){
    option <- "confirmacao"
  }
  
  # Faz todo o procedimento
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


generate_title <- function(moving_window = 14, cases = "total"){
  # Gera o título do gráfico, de acordo os inputs.
  
  # moving_window = janela móvel dos dados
  # cases = se os casos serão medidos pelo nº total ("total"), ou por 100 mil habitantes ("100mil")
  
  titulo = "Casos de covid no DF por "
  
  # Se cases for igual a "100mil", já para por aqui e retorna.
  if(cases == "100mil"){
    titulo = stringr::str_c(titulo, "100 mil habitantes")
    return(titulo)
  }
  
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
    my_caption = "Nota: por quinzena móvel, por data dos primeiros sintomas\nFonte: SESDF / SSP-DF \nElaboração: Rodrigo Stuckert"
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
cases = "total"
moving_window <- 14 # Janela móvel de casos
file_path <- "datasets/georref/Regiões Administrativas.shp" # Endereço dos dados geoespaciais


# Gera o dataframe com os casos móveis
df_final <- generate_df(df, first_day, last_day, moving_window = 14,
                     option = "sintomas", endereco_geo = file_path)


# Pega a população de cada RA, para gerar os casos por 100 mil habitantes
df_population <- data.table::fread("datasets/populacao.csv", encoding = "UTF-8")
df_population <- df_population %>%
  select(-c("pop_pct"))
df_final_pop <- inner_join(df_final, df_population, by = "RA") %>%
  mutate(casos_moveis_100mil = (100000 * (casos_moveis / pop)))
View(df_final_pop[, c(1, 2, 3, 4, 6, 7)])


# Cria o título e a caption do gráfico
my_title <- generate_title(moving_window)
my_caption <- generate_caption(option = opcao, cases = "total")



#### PARTE GRÁFICA ####


# Para o gráfico não ter marcas nos eixos
no_axis <- theme(axis.title=element_blank(),
                 axis.text=element_blank(),
                 axis.ticks=element_blank())

# Render com um único dia (para teste)
my_gif_test <- df_final_pop %>%
  filter(DataCadastro == as.Date("2020-07-31")) %>% # Dia que já tinha vários casos
  ggplot((aes(geometry = geometry, fill = casos_moveis))) +
  geom_sf(size = 1L, stat = "sf") + # Coordenadas
  geom_sf_text(aes(label = RA), size = 3, check_overlap = TRUE) + # Nome das RAs
  scale_fill_distiller(palette = "OrRd", direction = 1) + # Paleta de cores
  labs(title = my_title,
       subtitle='{frame_time}',
       fill = "Casos",
       caption = my_caption) +
  theme_minimal() + # Fundo branco
  theme(plot.title = element_text(face = "bold"), # Título em negrito
        plot.caption = element_text(hjust = 0)) + # Caption na esquerda
  no_axis

my_gif_test

  
# Gif final

my_caption <- generate_caption(option = opcao, cases = "100mil")

my_gif_pop <- df_final_pop %>%
  filter(DataCadastro >= as.Date("2020-04-01")) %>% # Datas a partir desse dia
  ggplot((aes(geometry = geometry, fill = casos_moveis_100mil))) +
  geom_sf(size = 1L, stat = "sf") + # Coordenadas
  geom_sf_text(aes(label = RA), check_overlap = TRUE, size = 3) + # Nome das RAs
  #ggrepel::geom_label_repel(aes(label = RA, geometry = geometry),
  #                          stat = "sf_coordinates",  min.segment.length = 0) +
  scale_fill_distiller(palette = "OrRd", direction = 1) + # Paleta de cores
  labs(title = "Casos de covid no DF por 100mil habitantes",
       subtitle='{frame_time}',
       fill = "Casos",
       caption = my_caption) +
  theme_minimal() + # Fundo branco
  theme(plot.title = element_text(face = "bold"), # Título em negrito
        plot.caption = element_text(hjust = 0)) + # Caption na esquerda
  no_axis +
  # GGanimate agora:
  transition_time(DataCadastro) +
  ease_aes('linear') # Método de suavização



# Salva na pasta e conta o tempo de execução
start_time <- Sys.time()
anim_save(file = "my_gif_pop.gif", my_gif_pop, renderer = gifski_renderer(), fps = 11, 
          width = 600, height = 450)
print(Sys.time() - start_time)

my_gif  