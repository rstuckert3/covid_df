# Análise dos dados da covid no Distrito Federal (DF)

O script baixa os dados com a série histórica da Secretaria de Saúde do Distrito Federal (SESDF) das informações referentes aos casos de coronavírus no Distrito Federal. Os dados são obtidos por meio do [Painel COVID-19 no Distrito Federal](https://covid19.ssp.df.gov.br/extensions/covid19/covid19.html#/).

Cabe ressaltar que, ao que tudo indica, inicialmente, a SESDF registrava os dados sobre presença de comorbidades (Sim / Não) apenas quando a pessoa apresentava positivo para alguma, deixando as informações para as demais pessoas todas como NA. A partir do final de abril/2020, o protocolo parece ter mudado, de modo que um mesmo indivíduo com "Sim" para alguma comorbidade poderia ter "Não" e NA para as demais. Desse modo, optamos por considerar todos os NA's como "Não" no tratamento dos dados.

## Dados abertos
Os dados podem ser acessados no [site da Secretaria de Segurança Pública do DF](https://covid19.ssp.df.gov.br/resources/dados/dados-abertos.csv?param=[random]). 

### Colunas
O CSV é composto das colunas abaixo:

* id = Número de identificação do indivíduo.
* Data = Data da última atualização daquele banco de dados (constante entre as observações) (%%d/%%mm/%yyyy).
* Data Cadastro = Data do cadastro da pessoa no banco de dados (%%d/%%mm/%yyyy)
* Sexo = sexo do indivíduo.
* Faixa Etária = faixa etária do indivíduo. Agrupada em seis categorias(<= 19 anos, 20 a 29 anos, 30 a 39 anos, 40 a 49 anos, 50 a 59 anos, >= 60 anos).
* RA = Região Administrativa (RA) da pessoa. Apresenta 36 opções entre as RA's do Distrito Federal, mais a opção "Outros Estados", para casos de fora do DF.
* UF = Unidade da Federação.
* Óbito¹ = Se a pessoa foi a óbito até a presente data ou não (Sim, Não).
* dataPrimeirosintomas = Data em que a pessoa se recorda ter apresentado os primeiros sintomas. (%%d/%%mm/%yyyy)
* Pneumopatia = Apresenta pneumopatia? (Sim, Não)
* Nefropatia = Apresenta nefropatia? (Sim, Não)
* Doença Hematológica = Apresenta doença hematológica? (Sim, Não)
* Distúrbios Metabólicos = Apresenta distúrbios metabólicos? (Sim, Não)
* Imunopressão = Apresenta imunopressão? (Sim, Não)
* Obesidade = Apresenta obesidade? (Sim, Não)
* Outros = Apresenta outras comorbidades?
* Cardiovasculopatia = Apresenta cardiovascuolopatia? (Sim, Não)

* ¹: anteriormente, a variável "Óbito" se chamada "Estado Saúde" e constava se a pessoa tinha ido a óbito, se estava internada (Leve, Moderado, Grave), se era um caso ativo, ou se estava recuperada (viva após cerca de duas semanas de contaminação). A mudança passou a valer a partir do dia 2020-07-10.
