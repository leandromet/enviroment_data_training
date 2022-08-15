#Exemplo com dados já existentes em qualquer versão do R, para complementar introdução no curso de dados ambientais 2022

#Outro tutorial usando os mesmos dados em: https://allisonhorst.github.io/palmerpenguins/
#Mais exemplos com este dataset em: https://allisonhorst.github.io/palmerpenguins/articles/examples.html
#muitos exemplos de gráficos e formatos em: https://r-graph-gallery.com/



#instalar pacote
install.packages("tidyverse")

#abrir pacote
library(tidyverse)
library(lubridate)

#testes com o pacote palmerpenguins que já vem no R para testes e aprendizado
package("palmerpenguins")

#necessário instalar antes
install.packages("palmerpenguins")
library("palmerpenguins")

# resumo do que há no pacote
summary("palmerpenguins")

#dataset penguins (tabela)
summary(penguins)

# visualizar tabela
View(penguins)


#Grafico dos dados , estrutura
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g))
#Gráfico padrão com pontos para 2 variáveis
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point()
#Gráfico padrão com colunas para 2 variáveis
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_col()

#Histograma no ggplot
ggplot(data=penguins,aes(x=flipper_length_mm)) + geom_histogram(bins=10)
#mas aí é melhor usar o histograma padrão
flip_length <- penguins$flipper_length_mm
hist(flip_length)
#Que pode ser personalizado e tem um layout também padrão
hist(flip_length,
     main="Comprimento dos Penguins",
     xlab="comprimento em mm",
     xlim=c(150,250),
     col="darkmagenta",
     freq=TRUE
)
#Posso usar a função de estética (AESthetic) para colorir conforme um dos atributos
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(color=species))
#Usar formas para os pontos e separar em quadros de acordo com o mesmo ou outro atributo
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(shape=species))+facet_wrap(~species)
#Colocar um título e colorir pelo mesmo atributo
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(shape=species,color=species))+facet_wrap(~year + sex)+labs(title="Palmer teste")
# Usar outro atributo (ano) para separar e colorir por espécie
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(shape=species,color=species))+facet_wrap(~year)+labs(title="Palmer teste")
# Usar dois atributos para fazer os gráficos combinados
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(shape=species,color=species))+facet_wrap(~year + sex)+labs(title="Palmer teste")
# Incluir mais informações e componentes no gráfico 
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(shape=species,color=species))+facet_wrap(~species)+labs(title="Peso e Comprimento dos Penguins",subtitle = "Data were collected and made available by Dr. Kristen Gorman \n and the Palmer Station, Antarctica LTER, a member of the Long Term \n Ecological Research Network.", caption = "https://allisonhorst.github.io/palmerpenguins/ ",x="Comprimento (mm)",y="Peso (g)")
# Mudar o tipo de gráfico com os mesmos componentes
ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_col(aes(shape=species,color=species))+facet_wrap(~species)+labs(title="Peso e Comprimento dos Penguins",subtitle = "Data were collected and made available by Dr. Kristen Gorman \n and the Palmer Station, Antarctica LTER, a member of the Long Term \n Ecological Research Network.", caption = "https://allisonhorst.github.io/palmerpenguins/ ",x="Comprimento (mm)",y="Peso (g)")

# E aquele histograma? Aqui eu posso dividir por grupos coloridos
ggplot(data=penguins,aes(x=flipper_length_mm, fill = species)) + geom_histogram(bins=10)+facet_wrap(~species)
