################################################################################
#################### Análise exploratória de Dados #############################
################################################################################

library(ggplot2)
library(ggalluvial)
library(dplyr)
library(stringr)

# Dados ------------------------------------------------------------------------

dados  <- read.csv(file = "00_Dados/01_Processed/dados_processados.csv")

# Manipulação ------------------------------------------------------------------
# Conversão das classes das variáveis
for (i in 1:ncol(dados)) {
  if (is.character(dados[[i]])) {
    dados[[i]] <- as.factor(dados[[i]])
  }
}

sapply(dados, class)

summary(dados)



# Objetivo ---------------------------------------------------------------------

# Identificar,  com base nos propósitos, o padrão de fornecimento de empréstimo, 
# os principais fatores relacionados a inadimplência e campos disponíveis para
# fornecimento de novas linhas de crédito. 

# EDA --------------------------------------------------------------------------

# Resultado 1 - Plot 1-  Status ocupacional por idade e gênero---------------

P1 <- dados%>%
  ggplot(aes(idade_anos,  y = genero))+
  geom_violin(alpha = 0.4, fill = "#440154", color = "white")+
  geom_boxplot(width = 0.28, fill = "#440154", color = "black")+
  labs(x = "Idade (anos)",
       y = "Densidade",
       fill = "Gênero:",
       title = "Idade por gênero")+
  scale_x_continuous(breaks = seq(from = 20, to = 80, by = 10))+
  theme_minimal()+
  theme(text = element_text(size = 14, face = "bold"),
        plot.title = element_text(hjust = 0.5))
P1

# Resultado 2 - Taxa de inadimplência por propósito-----------------------------
dados$proposito <- as.factor(dados$proposito)
propositos <- levels(dados$proposito)

TxInadimplencia <- data.frame("Proposito" = character(0), "TaxaDeInadimplencia" = numeric(0))

TotalTxInadimplencia <- data.frame("hist_credito" = character(0), "FreqRel" = numeric(0),
                                    "proposito"  = character(0))

for (i in propositos) {
  denominador <- dados %>%
    filter(proposito == i) %>%
    summarise(totalgrupo = n())
  Tx_Inadimplencia <- dados %>%
    filter(proposito == i) %>%
    group_by(hist_credito) %>%
    summarise(FreqRel = n() / denominador$totalgrupo)
  Tx_Inadimplencia$proposito = i
  TotalTxInadimplencia = rbind(TotalTxInadimplencia, Tx_Inadimplencia)
}

Inadimplencia <-  TotalTxInadimplencia%>%
  filter(hist_credito == "Pendente (outros bancos)"|
           hist_credito == "Pago mas já esteve em atraso")
# 
# Inadimplencia <- Inadimplencia %>%
#   mutate(hist_credito = str_replace_all(hist_credito,
#                                         c("atraso no pagamento no passado" = "Atraso no passado",
#                                           "conta crítica/outros créditos existentes (não neste banco)" = "Atraso no presente (não neste banco)")))

InadimplenciaGeral <- Inadimplencia%>%
  group_by(proposito)%>%
  summarise(InadimplenciaTotal= sum(FreqRel))



#  Gera a taxa de inadimplência por grupo filtrado
denominador <- dados%>%
  filter(proposito == "eletrodomésticos")%>%
  summarise(totalgrupo = n())

Tx_Inadimplencia <- dados%>%
  filter(proposito == "eletrodomésticos")%>%
  group_by(hist_credito)%>%
  summarise(FreqRel = n()/denominador)

# Resultado 2.1 - Histórico de crédito por propósito

TotalTxInadimplencia%>%
  mutate(hist_credito = factor(hist_credito, levels = c("Quitados",
                                                        "Pago mas já esteve em atraso",
                                                        "Pendente (outros bancos)",
                                                        "Pago em dia")))%>%
ggplot() +
  aes(x = hist_credito, y = FreqRel) +
  geom_col() +
  coord_flip() +
  theme_minimal() +
  facet_wrap(vars(proposito))+
  labs(x = "Propósito",
       y = "Composição",
       color = "Propósito")+
  scale_fill_viridis_d()+
  theme_bw()+
  theme(text = element_text(size = 14, face = "bold"),
        legend.position = "bottom")

ggplot(TotalTxInadimplencia) +
  aes(x = proposito, y = FreqRel, fill = hist_credito) +
  geom_col() +
  coord_flip()+
  labs(x = "Propósito",
       y = "Composição",
       color = "Propósito")+
  scale_fill_viridis_d()+
  theme_bw()+
  theme(text = element_text(size = 14, face = "bold"),
        legend.position = "bottom")

# Resultado 2.2 - Inadimplência por propósito

ggplot(Inadimplencia) +
  aes(x = reorder(proposito, FreqRel), y = FreqRel, fill = hist_credito) +
  geom_col() +
  coord_flip() +
  labs(x = "Propósito",
       y = "Composição",
       color = "Propósito")+
  scale_fill_viridis_d()+
  theme_minimal()+
  theme(text = element_text(size = 14, face = "bold"),
        legend.position = "bottom")

# Resutado 2.3 - Inadimplência geral

ggplot(InadimplenciaGeral) +
  aes(x = reorder(proposito, InadimplenciaTotal), y = InadimplenciaTotal ) +
  geom_col() +
  coord_flip() +
  labs(x = "Propósito",
       y = "Inadimplência")+
  scale_color_viridis_d()+
  theme_bw()+
  theme(text = element_text(size = 14, face = "bold"),
        legend.position = "bottom")


# Resultado 3 - Plot 2 - Quantidade de crédito x idade x propósito x reserva ----------

dados <- dados %>%
  mutate(reserva = str_replace_all(reserva, 
                                   c("desconhecido/semcontapoupança" = "Desconhecido/Inexistente")))

P2 <- dados%>%
  mutate(reserva = factor(reserva, levels = c("Desconhecido/Inexistente",
                             "< 100","100 - 500","500 - 1000",
                             "> 1000")))%>%
  ggplot(aes(idade_anos, qtdd_credito, color =proposito))+
  geom_jitter( size = 3)+
  facet_wrap(~reserva, nrow = 1, 
             labeller = labeller(reserva = c(
               "Desconhecido/Inexistente" = "Desconhecido\nInexistente",
               "< 100" = "< 100",
               "100 - 500" = "100 - 500",
               "500 - 1000" = "500 - 1000",
               "> 1000" = "> 1000"
             ))
  )+
  labs(x = "Idade (anos)",
       y = "Crédito disponível",
       color = "Propósito")+
  scale_color_viridis_d()+
  theme_bw()+
  theme(text = element_text(size = 14, face = "bold"),
        legend.position = "bottom")
P2
plotly::ggplotly(P2)

# Resultado 4 - Média de crédito por  propósito e gênero -----------------------
  RESUMO <- dados%>%
  group_by(proposito,genero)%>%
  summarise("Média" = mean(qtdd_credito),
            "Desvio padrão" = sd(qtdd_credito),
            "Mínimo" = min(qtdd_credito),
            "1º Quartil" = quantile(qtdd_credito, 0.25),
            "Mediana" = quantile(qtdd_credito, 0.5),
            "3º Quartil" = quantile(qtdd_credito, 0.75),
            "Máximo" = max(qtdd_credito))
# Média de cŕedito por propósito (MOSTRAR  GERAL EM CARD)
# Resultado 5 - Plot 3  Disparidades das médias de crédito fornecido por genero------

P3 <- RESUMO%>%
  ggplot(aes(x = genero, y = `Média`, group = proposito))+
  geom_line(aes(color = proposito), size = 1.5)+
  geom_point(aes(color = proposito),size = 3)+
  labs(x = "Gênero",
       y = "Media de crédito concedido", 
       color = "Propósito")+
  theme_minimal()+
  scale_color_viridis_d()+
  theme(text = element_text(size = 14, face = "bold"))
print(P3)

plotly::ggplotly(P3)


# Resultado 6 - Média de crédito por histórico de cŕedito e genero -------------
RESUMO2<- dados%>%
  group_by(hist_credito,genero)%>%
  summarise("Média" = mean(qtdd_credito),
            "Desvio padrão" = sd(qtdd_credito),
            "Mínimo" = min(qtdd_credito),
            "1º Quartil" = quantile(qtdd_credito, 0.25),
            "Mediana" = quantile(qtdd_credito, 0.5),
            "3º Quartil" = quantile(qtdd_credito, 0.75),
            "Máximo" = max(qtdd_credito))

P4 <- RESUMO2%>%
  ggplot(aes(x = genero, y = `Média`, group = hist_credito))+
  geom_line(aes(color = hist_credito), size = 1.5)+
  geom_point(aes(color = hist_credito),size = 3)+
  labs(x = "Gênero",
       y = "Media de crédito concedido", 
       color = "Histórico de pagamento")+
  theme_minimal()+
  scale_color_viridis_d()+
  theme(text = element_text(size = 14, face = "bold"),
        legend.position = "bottom")
print(P4)

plotly::ggplotly(P4)

# Resultado 7 - Patrimônio e status da conta por gênero --------------------------------------

dados$patrimonio <- ifelse(dados$patrimonio == "desconhecido/sem propriedade", "Sem posses/\ndesconhecido",
                           ifelse(dados$patrimonio == "carro ou outro, não em conta poupança/títulos", "Carro/outro",
                                  ifelse(dados$patrimonio == "contrato de poupança/seguro de vida da sociedade civil", "Poupança/\nSeguro de vida",
                                         ifelse(dados$patrimonio == "imobiliária", "Imóvel", dados$patrimonio))))

# status da conta x patrimonio x gênero
P5 <- dados%>%
  mutate(status_conta = 
           factor(status_conta, 
                  levels = c("Alto","Regular",
                             "Negativo","Inexistente")))%>%
  mutate(patrimonio = 
           factor(patrimonio, 
                  levels = c("Sem posses/\ndesconhecido", "Carro/outro",
                             "Poupança/\nSeguro de vida","Imóvel")))%>%
  
  ggplot() +
  aes(x = patrimonio, fill = status_conta) +
  geom_bar(position = "fill") +
  theme_minimal() +
  labs(x = "Patrimonio",
       y = "(%)",
       color = "Status da conta")+
  scale_fill_manual(values = c("#fde725",
                               "#5ec962",
                               "#21918c",
                               "#440154"))+
  facet_wrap(vars(genero))+
  theme_minimal()+
  theme(text = element_text(size = 14, face = "bold"))
  
plotly::ggplotly(P5)

# Resultado 8 - Duração do parcelamento  idade e tempo de manutenção do emprego --------------
P6 <- dados%>%
  ggplot(aes(idade_anos, duracao_mes, size = percen_tx_rendim_disp, color = outros_par))+
  geom_point( alpha = 0.7)+
  scale_color_manual(values = c("#fde725","#440154","#21918c"))+
  facet_wrap(genero~temp_man_empr_atual, nrow = 2)+
  labs(x = "Idade (anos)",
       y = "Duração dos parcelamentos (mês)",
       size = "Percentual\n da taxa de juros\n com relação ao salário",
       color = "Existencia de\noutros parcelamentos")+
  theme_bw()+
  theme(text = element_text(size = 14, face = "bold"))
  

# Resultado 9 - Perfil habitacional --------------------------------------------

COUNT <- dados%>%
  count( habitacao, tempo_res_atual, patrimonio, n_corresponsaveis, genero)

P7 <- COUNT%>%
  ggplot(aes(y = n, axis1 = genero,
             axis2 = habitacao,
             axis3 =  n_corresponsaveis,
             axis4 = tempo_res_atual,
             axis5 = patrimonio)) +
  geom_alluvium(aes(fill = genero), aes.bind= "flows", width = 1/12) +
  geom_stratum(width = 1/4, fill = "white", color = "black") +
  geom_text(stat = "stratum", label.strata = TRUE) +
  scale_x_discrete(limits = c( "Gênero", "Habitação","Nº de corresponsáveis",
                               "Tempo na\nresidência\n
                               atual", "Patrimônio"),
                   # ,"patrimonio","reserva"),
                   expand = c(.05, .05)) +
  labs(y = "Cases") +
  theme_minimal() +
  theme(legend.position = "none") +
  ggtitle("Perfil Habitcional")+
  scale_fill_viridis_d()


# Resultado 10 - Perfil ocupacional---------------------------------------------
COUNT <- filtrado%>%
  count( habitacao, tempo_res_atual, patrimonio, n_corresponsaveis, genero)

COUNT%>%
  ggplot(aes(y = n, axis1 = genero,
             axis2 = habitacao,
             axis3 =  n_corresponsaveis,
             axis4 = tempo_res_atual,
             axis5 = patrimonio)) +
  geom_alluvium(aes(fill = genero), aes.bind= "flows", width = 1/12) +
  geom_stratum(width = 1/4, fill = "white", color = "black") +
  geom_text(stat = "stratum", label.strata = TRUE) +
  scale_x_discrete(limits = c( "Gênero", "Habitação","Nº de corresponsáveis",
                               "Tempo na\nresidência\n
                               atual", "Patrimônio"),
                   # ,"patrimonio","reserva"),
                   expand = c(.05, .05)) +
  labs(y = "Cases") +
  theme_minimal() +
  theme(legend.position = "none") +
  ggtitle("Perfil Habitcional")+
  scale_fill_viridis_d()




dados$status_ocupacional <- ifelse(dados$status_ocupacional == 
                                     "desempregado/não qualificado - não residente", "Desempregado/\nnão qualificado",
                                   ifelse(dados$status_ocupacional == "funcionário/funcionário qualificado", "Empregado\nqualificado",
                                          ifelse(dados$status_ocupacional == "gestão / autônomo / funcionário / diretor altamente qualificado", "Empregado em \n cargo superior\n qualificado",
                                                 ifelse(dados$status_ocupacional == "não qualificado - residente", "Desempregado/\nnão qualificado", dados$status_ocupacional))))


dados <- dados%>%
  mutate(temp_man_empr_atual = factor(temp_man_empr_atual, 
                                      levels = c("> 7", "4 - 7","1 - 4",
                                                 "...<1ano","desempregado")))%>%
  mutate(status_ocupacional = factor(status_ocupacional, levels = c(
    "Empregado em \n cargo superior\n qualificado", "Empregado\nqualificado","Desempregado/\nnão qualificado"
  )))


COUNT2 <- dados%>%
  count(temp_man_empr_atual,status_ocupacional,estrangeiro,  genero)


P8 <- COUNT2 %>%
  ggplot(aes(y = n, axis1 = genero,
             axis2 = estrangeiro,
             axis3 = status_ocupacional,
             axis4 = temp_man_empr_atual)) +
  geom_alluvium(aes(fill = genero), aes.bind = "flows", width = 1/12) +
  geom_stratum(width = 1/3, fill = "white", color = "darkgray") +
  geom_text(stat = "stratum", aes(label = after_stat(stratum)), size = 3) +
  scale_x_discrete(limits = c("axis1" = "Gênero", 
                              "axis2" = "Imigrante",
                              "axis3" = "Status\nocupacional",
                              "axis4" = "Tempo no\nemprego\natual"),
                   expand = c(.05, .05)) +
  labs(y = "Cases", title = "Perfil Habitcional") +
  theme_minimal() +
  theme(legend.position = "none") +
  scale_fill_manual(values = c("#21918c", "#440154"))+
  geom_label(stat = "stratum", aes(label = after_stat(stratum)),
             fontface = "bold", size = 3) 


P8

plotly::ggplotly(P8)

write.csv(dados, file = "00_Dados/01_Processed/dados_processados_2.csv")
#-------------------------------------------------------------------------------
# Quantidade de cŕedito por duração/mês

dados%>%
  ggplot(aes(qtdd_credito, duracao_mes, color = genero))+
  geom_jitter(size = 5, alpha  = 0.7 )+
  geom_smooth(alpha = 0.3)+
  facet_wrap(~habitacao)


# Histórico de crédito e status da conta

P3 <- ggplot(dados) +
  aes(x = status_conta, fill = hist_credito) +
  geom_bar(position = "fill") +
  scale_fill_hue(direction = 1) +
  theme_minimal()
plotly::ggplotly(P3)


# as pessoas que estão com divida ou parcela são as que tem casa própria?
# quais são os propósitos de quem já tem casa própria?

P4 <- ggplot(dados) +
  aes(x = patrimonio, fill = reorder(proposito, patrimonio)) +
  geom_bar(position = "fill") +
  scale_fill_hue(direction = 1) +
  theme_minimal()

plotly::ggplotly(P4)

# proposito e status 
# Gráfico de Barras Empilhadas para Propósito de Empréstimo e Status da Conta:

#Integrando Cenário Patrimonial e Histórico de Crédito: Analise a distribuição 
# do propósito do empréstimo em relação ao status da conta. Isso pode ajudar a
# identificar se certos propósitos de empréstimo estão associados a um melhor 
# histórico de crédito.

P5 <- ggplot(dados) +
  aes(x = status_conta, fill = patrimonio) +
  geom_bar(position = "fill") +
  scale_fill_hue(direction = 1) +
  theme_minimal()

plotly::ggplotly(P5)

plot <- patrcount %>%
  ggplot(aes(y = n, axis1 = patrimonio, axis3 = proposito, axis2 = reserva)) +
  geom_alluvium(aes(fill = reserva), aes.bind = "flows", width = 1/12) +
  geom_stratum(width = 1/4, fill = "white", color = "black") +
  geom_text(stat = "stratum", label.strata = TRUE, color = "black") +
  scale_x_discrete(limits = c("Patrimônio", "Propósito", "Reserva/\npoupança"),
                   expand = c(.05, .05)) +
  scale_fill_manual(values = c("#006b5e", "#ff6600", "#970000", "#dc6bdb", "#007a00")) +
  labs(y = "Cases") +
  theme_minimal() +
  theme(legend.position = "none") +
  ggtitle("Perfil sociodemográfico")

plot

plotly::ggplotly(plot)



contagem <- dados%>%
  count(proposito)

contagem%>%
  mutate(proposito = str_to_title(proposito))%>%
  ggplot() +
  aes(x = reorder(proposito,n, decreasing = F), y  = n) +
  geom_col(fill = "#21918c") +
  labs(x = "Propósitos",
       y = "Nº de clientes com este proposito")+
  coord_flip()+
  theme_minimal()+
  theme(text = element_text(size = 18, face = "bold"))


