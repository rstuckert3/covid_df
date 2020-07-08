## Dados abertos
Para assegurar a disponibilidade dos dados, foram baixados os dados disponíveis no dia 2020-07-08 às 12h. Cabe ressaltar que a Secretaria de Saúde do Distrito Federal (SESDF) realiza duas atualizações diárias: uma ao meio-dia, e outra às 18h.
Os dados mais recentes podem ser acessados no [site da Secretaria de Segurança Pública do DF](https://covid19.ssp.df.gov.br/resources/dados/dados-abertos.csv?param=[random]). 

### Colunas
O CSV é composto das colunas abaixo:

* id = Número de identificação do indivíduo.
* Data = Data da última atualização daquele banco de dados (constante entre as observações) (%%d/%%mm/%yyyy).
* Data Cadastro = Data do cadastro da pessoa no banco de dados (%%d/%%mm/%yyyy)
* Sexo = sexo do indivíduo.
* Faixa Etária = faixa etária do indivíduo. Agrupada em seis categorias(<= 19 anos, 20 a 29 anos, 30 a 39 anos, 40 a 49 anos, 50 a 59 anos, >= 60 anos).
* RA = Região Administrativa (RA) da pessoa. Apresenta 36 opções entre as RA's do Distrito Federal, mais a opção "Outros Estados", para casos de fora do DF.
* UF = Unidade da Federação.
* Estado de Saúde = Última informação quanto ao estado de saúde daquela pessoa (Leve, Moderado, Grave, Não Informado, Óbito, Recuperado).
* Pneumopatia = Apresenta pneumopatia? (Sim, Não)
* Nefropatia = Apresenta nefropatia? (Sim, Não)
* Doença Hematológica = Apresenta doença hematológica? (Sim, Não)
* Distúrbios Metabólicos = Apresenta distúrbios metabólicos? (Sim, Não)
* Imunopressão = Apresenta imunopressão? (Sim, Não)
* Obesidade = Apresenta obesidade? (Sim, Não)
* Outros = Apresenta outras comorbidades?
* Cardiovasculopatia = Apresenta cardiovascuolopatia? (Sim, Não)
