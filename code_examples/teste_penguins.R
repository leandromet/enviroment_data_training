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

summary(penguins)

View(penguins)

ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g))

ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point()

ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_col()


#Histograma no ggplot

ggplot(data=penguins,aes(x=flipper_length_mm)) + geom_histogram(bins=10)

#mas aí é melhor usar o histograma padrão
flip_length <- penguins$flipper_length_mm
hist(flip_length)

hist(flip_length,
     main="Comprimento dos Penguins",
     xlab="comprimento em mm",
     xlim=c(150,250),
     col="darkmagenta",
     freq=TRUE
)




ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(color=species))

ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(shape=species))+facet_wrap(~species)

ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(shape=species))+facet_wrap(~species)+labs(title="Palmer teste")

ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_point(aes(shape=species,color=species))+facet_wrap(~species)+labs(title="Palmer teste")

ggplot(data=penguins,aes(x=flipper_length_mm,y=body_mass_g)) + geom_col(aes(shape=species,color=species))+facet_wrap(~species)+labs(title="Palmer teste")


# E aquele histograma? Aqui eu posso dividir por grupos coloridos
ggplot(data=penguins,aes(x=flipper_length_mm, fill = species)) + geom_histogr
