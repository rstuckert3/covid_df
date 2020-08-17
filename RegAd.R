library(sf)
library(ggplot2)

RegioesAdm <- st_read("datasets/georref/Regiões Administrativas.shp")
colnames(RegioesAdm)[2] <- "RA"

Regioes_bkp <- RegioesAdm[,c(2, 8)]

df_RA <- df %>% 
        group_by(RA) %>%
        summarise(casos = n(),
                  obitos = sum(Obito),
                  mortalidade = obitos / casos,
                  pct_comorbidade = sum(Comorbidade == 1) / casos,
                  pct_mulheres = sum(Sexo == "Feminino")/casos,
                  pct_homens = 1 - pct_mulheres
        )

geo_RAs = left_join(RegioesAdm, df_RA, by='RA')

no_axis <- theme(axis.title=element_blank(),
                 axis.text=element_blank(),
                 axis.ticks=element_blank())


geo_RAs$mortalidade <- geo_RAs$mortalidade * 100

geo_RAs %>%
 ggplot((aes(fill = mortalidade))) +
  geom_sf(size = 1L) +
  geom_sf_text(aes(label = RA), size = 2L) +
  scale_fill_distiller(palette = "OrRd", direction = 1) +
  theme_minimal() +
  labs(fill = "Mortalidade %") +
  no_axis
        
#library(esquisse)
#esquisser(geo_RAs)