### Source for Chapter 9 codes

## Wan M Hasni and Azman Hussin
## This codes will be run prior to running the Rmd files for Chapter 9
## All the plots will be labeled as figxxx and called inside the Rmd files

## Load the libraries
library(tidyverse)
library(tidytext)
library(ggplot2)
library(igraph)
library(ggraph)
library(graphlayouts)
library(quRan)
library(quanteda)
library(readtext)
library(topicmodels)
library(udpipe)
library(textrank)
library(wordcloud)
library(scales) # for formatting numbers in output
library(grid)
library(png)
library(jpeg)
library(readr)


## load quran sahih 
kvertices <- quran_en_sahih %>% 
  select(ayah_title, surah_id, ayah, ayah_id,
         surah_title_en, revelation_type, text)

## load ibnu_kathir and process
kathir <- read_csv("data/ibn_kathir_similarity.csv", 
                   col_types = cols(ID = col_integer(), 
                                    Source_Sura = col_integer(), Source_Verse = col_integer(), 
                                    Target_verse = col_integer(), common_roots = col_integer(), 
                                    relevance_degree = col_integer(), 
                                    target_sura = col_integer()))
kathir <- kathir %>% 
  rename(SourceSura = Source_Sura, SourceAyah = Source_Verse,
         TargetSura = target_sura, TargetAyah = Target_verse)

kathir <- kathir %>% 
  drop_na() %>%  
  mutate(from = str_c(as.character(SourceSura),
                      as.character(SourceAyah),sep = ":"),
         to = str_c(as.character(TargetSura),
                    as.character(TargetAyah),sep = ":")) %>%
  rename(weight = relevance_degree)

## create edge-list
kedges <- kathir %>% 
                select(from, to, SourceSura, SourceAyah, TargetSura, TargetAyah, common_roots, weight)

kg = graph_from_data_frame(kedges, directed = TRUE, vertices = kvertices)

## read files for nodes and attributes from gephi output
ik_gephi = read_csv("data/ik1_nodes.csv")

## Katheer Graph Network stats
kg_degree = data.frame("verse"=1:6236, "degree"= degree(kg))
fig901a = kg_degree %>%  ggplot() + 
  geom_point(aes(x=verse,y=degree), color = "steelblue", alpha = 0.75) +
  labs(title="A: Degree of verses",x = "Verse", y = "Degree")

kg_degree_ranked = kg_degree[rev(order(kg_degree$degree)),]

fig901b = kg_degree_ranked %>% group_by(degree) %>% count() %>% 
  ggplot(aes(x=log(degree), y=log(n))) + 
  geom_point(color="steelblue", size = 3, alpha = 0.8, show.legend = FALSE) + 
  geom_path() +
  labs(title = "B: Rank frequency distributions", 
       x = "Log of Degree", 
       y = "Log of Rank Frequency")

kg_dist_table = distance_table(kg)

fig902 = ggplot() + geom_col(aes(x = 1:35,y=kg_dist_table$res), fill = "steelblue",color = 'black') +
  labs(x = "Distance", y = "Frequency")+
  scale_y_continuous(labels = scales::comma)+
  labs(title = "Katheer Graph Path Lengths Distributions")+
  theme_bw()

kgd = distances(kg, v = V(kg), to = V(kg), mode = "in")
# kgsp = shortest_paths(kg,from = "6:25", to = V(kg), mode = "in")
fig903a = data.frame("x" = 1:6236, "y" = kgd[,"6:25"]) %>% ggplot() + geom_point(aes(x,y), color="steelblue") +
  labs(x = "Verses", y = "Distance")

fig903b = data.frame("x" = 1:6236, "y" = kgd[,"6:25"]) %>% ggplot() + geom_density(aes(y), color="steelblue") +
  labs(x = "Verses", y = "Distance")  

## fig903: Centrality measures of verses in Ibnu Katheer: Prestige vs Betweeness
fig903c = ik_gephi %>% ggplot(aes(x = eigencentrality, y = betweenesscentrality)) + 
  geom_point(color = "cyan4") +
  geom_text(label=ik_gephi$Id, size = 3,
            nudge_x = 0.05, nudge_y = 0.05, 
            check_overlap = T) +
  labs(x = "Prestige Centrality", y = "Betweenness Centrality",
       title = "Centrality Measures of verses in Ibnu Katheer",
       subtitle = "Prestige vs Betweeness")+
  theme_bw()
## fig904: Centrality measures of verses in Ibnu Katheer: Pageranks vs Authority
fig904 = ik_gephi %>% ggplot( aes(x=pageranks, y=Authority)) +
  geom_point(size = 1, color = "cyan4") + 
  geom_text( aes(label=ik_gephi$Id), size = 3, check_overlap = T) +
  labs(x = "Pageranks", y = "Authority",
       title = "Centrality Measures of verses in Ibnu Katheer",
       subtitle = "Pageranks vs Authority")+
  theme_bw()


## TRAVERSALS IN SURAH AL-A'ALAA

## create the df for edges
surah87_l1 = kedges %>% filter(str_detect(to,"87:")) %>% select(from,to)
surah87_l2 = kedges %>% filter(to %in% surah87_l1$from) %>% select(from,to)
surah87_l3 = kedges %>% filter(to %in% surah87_l2$from) %>% select(from,to)
surah87_l4 = kedges %>% filter(to %in% surah87_l3$from) %>% select(from,to)
surah87_l5 = kedges %>% filter(to %in% surah87_l4$from) %>% select(from,to)

## Topic modeling within the verses

# 1. create a function to be used
## Use STM model for topics, get Topics as output
surah87_topics = function(txt87){
                    dfm_txt87 = quanteda::tokens(txt87,"word",remove_punct = T,
                               remove_symbols=T,
                               remove_numbers=T) %>% 
                    quanteda::tokens_tolower() %>% 
                    quanteda::tokens_remove(quanteda::stopwords("en")) %>%  
                    quanteda::dfm()
                    stmdfm_txt87 = quanteda::convert(dfm_txt87, to = "stm") 
                    stm_txt87 = stm::stm(stmdfm_txt87$documents, 
                                         stmdfm_txt87$vocab, K = 3, verbose = F,
                                         data = stmdfm_txt87$meta, 
                                         init.type = "Spectral")
                    stm::labelTopics(stm_txt87, c(1), n = 10)}

## 2. Run using the function

txt87 = quran_en_sahih %>% filter(ayah_title %in% surah87_l1$to) %>% pull(text)
topics_l0 = paste(surah87_topics(txt87)[["prob"]][1,], collapse = " ")

surah87n_l1 = surah87_l1
txt87 = quran_en_sahih %>% filter(ayah_title %in% 
                                    c(surah87n_l1$from,surah87n_l1$to)) %>% pull(text)
topics_l1 = paste(surah87_topics(txt87)[["prob"]][1,], collapse = " ")

surah87n_l2 = bind_rows(surah87_l1,surah87_l2)
txt87 = quran_en_sahih %>% filter(ayah_title %in% 
                                    c(surah87n_l2$from,surah87n_l2$to)) %>% pull(text)
topics_l2 = paste(surah87_topics(txt87)[["prob"]][1,], collapse = " ")

surah87n_l3 = bind_rows(surah87_l1,surah87_l2,surah87_l3)
txt87 = quran_en_sahih %>% filter(ayah_title %in% 
                                    c(surah87n_l3$from,surah87n_l3$to)) %>% pull(text)
topics_l3 = paste(surah87_topics(txt87)[["prob"]][1,], collapse = " ")

surah87n_l4 = bind_rows(surah87_l1,surah87_l2,surah87_l3,surah87_l4)
txt87 = quran_en_sahih %>% filter(ayah_title %in% 
                                    c(surah87n_l4$from,surah87n_l4$to)) %>% pull(text)
topics_l4 = paste(surah87_topics(txt87)[["prob"]][1,], collapse = " ")

surah87n_l5 = bind_rows(surah87_l1,surah87_l2,surah87_l3,surah87_l4,surah87_l5)
txt87 = quran_en_sahih %>% filter(ayah_title %in% 
                                    c(surah87n_l5$from,surah87n_l5$to)) %>% pull(text)
topics_l5 = paste(surah87_topics(txt87)[["prob"]][1,], collapse = " ")

## outputs are: topics_l1,..,l5

## 3. create igraph from edge list created above

surah87_net = graph_from_edgelist(as.matrix(surah87n_l5), directed = TRUE)

## then create measures to be quoted inside Rmd texts
ayat_topdegree = degree(surah87_net)
ayat_topdegree = ayat_topdegree[rev(order(ayat_topdegree))]
ayat_topdegree = names(ayat_topdegree[1:10])

ayat_topbtwn = betweenness(surah87_net)
ayat_topbtwn = ayat_topbtwn[rev(order(ayat_topbtwn))]
ayat_topbtwn = names(ayat_topbtwn[1:10])

ayat_topevcent = eigen_centrality(surah87_net)$vector
ayat_topevcent = ayat_topevcent[rev(order(ayat_topevcent))]
ayat_topevcent = names(ayat_topevcent[1:10])


## make some changes to the data, replace _ with :
ik_gephi$idnew =str_replace(ik_gephi$Id, "_",":") # change the separator

## create more variables to use for the tables in Rmd document
ayat_ovtdg = ik_gephi %>% filter(idnew %in% c(surah87n_l5$from,surah87n_l5$to)) %>% 
                              select(idnew, Degree,eigencentrality,betweenesscentrality) 
ayatdg = ayat_ovtdg[rev(order(ayat_ovtdg$Degree)),]
ayatbw = ayat_ovtdg[rev(order(ayat_ovtdg$betweenesscentrality)),]
ayatev = ayat_ovtdg[rev(order(ayat_ovtdg$eigencentrality)),]

## topics for top 10 grouped by Surah 87 net measures

topd10txt = quran_en_sahih %>% filter(ayah_title %in% ayat_topdegree) %>% pull(text)
td10 = surah87_topics(topd10txt)
topb10txt = quran_en_sahih %>% filter(ayah_title %in% ayat_topbtwn) %>% pull(text)
tb10 = surah87_topics(topb10txt)

ayatd10txt = quran_en_sahih %>% filter(ayah_title %in% ayatdg$idnew[1:10]) %>% pull(text)
ad10 = surah87_topics(ayatd10txt)
ayatb10txt = quran_en_sahih %>% filter(ayah_title %in% ayatbw$idnew[1:10]) %>% pull(text)
ab10 = surah87_topics(ayatb10txt)
## outputs used inside the Rmd text

#######################
## Traversing verse 13 Surah Al-A'laa 

## capture the edges for Surah Al-A'laa
vs8713 = kvertices %>% filter(ayah_title=="87:13") %>% pull(text)
vs3536 = kvertices %>% filter(ayah_title=="35:36") %>% pull(text)
vs4377 = kvertices %>% filter(ayah_title=="43:77") %>% pull(text)
vs2074 = kvertices %>% filter(ayah_title=="20:74") %>% pull(text)
vs1715 = kvertices %>% filter(ayah_title=="17:15") %>% pull(text)

# Making and plotting ego graphs
verse <- which(V(surah87_net)$name=="87:13")
v_name = V(surah87_net)$name
fig_egos87 = ggraph(surah87_net, layout = "focus", focus = verse) +
  draw_circle(col = "darkblue", use = "focus",max.circle = 10) +
  geom_edge_link0(aes(edge_width = 1),edge_colour = "grey66") +
  geom_node_point(aes(fill="red", size=3), shape = 21) +
  geom_node_text(size = 3,label = v_name,
                 family = "serif", repel=T) +
  scale_edge_width_continuous(range = c(0.1,2.0)) +
  scale_size_continuous(range = c(1,5)) +
  coord_fixed() +
  theme(legend.position = "none")

## Clustering measures
cld <- cluster_edge_betweenness(surah87_net, weights = NULL)
mem <- membership(cld)
com <- communities(cld)
#imc <- cluster_infomap(surah87_net)
# lec <- cluster_leading_eigen(surah87_net)
# sgc <- cluster_spinglass(surah87_net)
# wtc <- cluster_walktrap(surah87_net)

# Verse 87:13 ego network directed with clusters

## Figure 9.7 "map based brtweeness centrality
my_palette <- c("red", "blue", "green", "gold", "cyan4", "deeppink", "tomato", "yellow")
cld <- clusters(surah87_net)
V(surah87_net)$clu <- as.character(cld$membership)
V(surah87_net)$size <- graph.strength(surah87_net)

verse <- which(V(surah87_net)$name=="87:13")
v_name = V(surah87_net)$name
fig907x = ggraph(surah87_net,layout = "focus", focus = verse) +
    draw_circle(col = "darkblue", use = "focus",max.circle = 10) +
    geom_edge_link0(aes(edge_width=1), edge_color="grey66") +
    geom_node_point(aes(fill="red", size=size), shape=21, col="grey25") +
    geom_node_text(aes(size=2.5, label=v_name), family = "serif", repel=T) +
    scale_edge_width_continuous(range=c(0.1, 2.0)) +
    scale_size_continuous(range=c(1,10)) +
    theme(legend.position = "bottom")

## Verse 87:13 undirected ego network with centrality layout, clusters strength"}
kgu <- simplify(as.undirected(surah87_net))
clu <- cluster_louvain(kgu)
V(kgu)$clu <- as.character(clu$membership)
V(kgu)$size <- graph.strength(kgu)

fig909 = ggraph(kgu, "centrality", cent=graph.strength(kgu)) +
  draw_circle(col = "darkblue", use = "focus", max.circle = 10) +
  geom_edge_link0(edge_color="grey66") +
  geom_node_point(aes(fill=clu, size=size), shape=21, col="grey25") +
  geom_node_text(aes(size=2.5,label=name), repel=T) +
  scale_edge_width_continuous(range=c(0.1,2.0)) +
  scale_size_continuous(range=c(1,10)) +
    theme(legend.position = "bottom")

## Combining verses up to 4 layers outwards

v2255_l1 = kedges %>% filter(str_detect(from,"2:255")) %>% select(from,to)
v2255_l2 = kedges %>% filter(from %in% v2255_l1$to) %>% select(from,to)
v2255_l3 = kedges %>% filter(from %in% v2255_l2$to) %>% select(from,to)
v2255_l4 = kedges %>% filter(from %in% v2255_l3$to) %>% select(from,to)
#v2255_l5 = kedges %>% filter(to %in% v2255_l4$from) %>% select(from,to)

v2255 = bind_rows(v2255_l1,v2255_l2,v2255_l3,v2255_l4)
v2255_net = graph_from_edgelist(as.matrix(v2255), directed = TRUE)

v1690_l1 = kedges %>% filter(str_detect(from,"16:90")) %>% select(from,to)
v1690_l2 = kedges %>% filter(to %in% v1690_l1$from) %>% select(from,to)
v1690_l3 = kedges %>% filter(to %in% v1690_l2$from) %>% select(from,to)
v1690_l4 = kedges %>% filter(to %in% v1690_l3$from) %>% select(from,to)
v1690_l5 = kedges %>% filter(from %in% v1690_l4$to) %>% select(from,to)

v1690 = bind_rows(v1690_l1,v1690_l2,v1690_l3,v1690_l4,v1690_l5)
v1690_net = graph_from_edgelist(as.matrix(v1690), directed = TRUE)

verse <- which(V(v2255_net)$name=="2:255")
v_name = V(v2255_net)$name
fig910 = ggraph(v2255_net, layout = "focus", focus = verse) +
  draw_circle(col = "darkblue", use = "focus",max.circle = 4) +
  geom_edge_link0(aes(edge_width = 1),edge_colour = "grey66") +
  geom_node_point(aes(fill="red", size=3), shape = 21) +
  geom_node_text(size = 3,label = v_name,
                 family = "serif", repel=T) +
  scale_edge_width_continuous(range = c(0.1,2.0)) +
  scale_size_continuous(range = c(1,5)) +
  coord_fixed() +
  theme(legend.position = "none")

verse <- which(V(v1690_net)$name=="16:90")
v_name = V(v1690_net)$name
fig911 = ggraph(v1690_net, layout = "focus", focus = verse) +
  draw_circle(col = "darkblue", use = "focus",max.circle = 4) +
  geom_edge_link0(aes(edge_width = 1),edge_colour = "grey66") +
  geom_node_point(aes(fill="red", size=3), shape = 21) +
  geom_node_text(size = 3,label = v_name,
                 family = "serif", repel=T) +
  scale_edge_width_continuous(range = c(0.1,2.0)) +
  scale_size_continuous(range = c(1,5)) +
  coord_fixed() +
  theme(legend.position = "none")

v_combined = bind_rows(v2255,v1690)
vcomb_net = graph_from_edgelist(as.matrix(v_combined), directed = TRUE)

vcomb_net = graph.union(v2255_net,v1690_net)
verse <- which(V(vcomb_net)$name=="2:255")
v_name = V(vcomb_net)$name
fig912 = ggraph(vcomb_net, layout = "focus", focus = verse) +
  draw_circle(col = "darkblue", use = "focus",max.circle = 4) +
  geom_edge_link0(aes(edge_width = 1),edge_colour = "grey66") +
  geom_node_point(aes(fill="red", size=3), shape = 21) +
  geom_node_text(size = 3,label = v_name,
                 family = "serif", repel=T) +
  scale_edge_width_continuous(range = c(0.1,2.0)) +
  scale_size_continuous(range = c(1,5)) +
  coord_fixed() +
  theme(legend.position = "none")

verse <- which(V(vcomb_net)$name=="16:90")
v_name = V(vcomb_net)$name
fig913 = ggraph(vcomb_net, layout = "focus", focus = verse) +
  draw_circle(col = "darkblue", use = "focus",max.circle = 4) +
  geom_edge_link0(aes(edge_width = 1),edge_colour = "grey66") +
  geom_node_point(aes(fill="red", size=3), shape = 21) +
  geom_node_text(size = 3,label = v_name,
                 family = "serif", repel=T) +
  scale_edge_width_continuous(range = c(0.1,2.0)) +
  scale_size_continuous(range = c(1,5)) +
  coord_fixed() +
  theme(legend.position = "none")

#### Word co-occurrence KG
library(text2vec)

## get the texts

surah87_o1 = kedges %>% filter(str_detect(from,"87:")) %>% select(from,to)
surah87_o2 = kedges %>% filter(from %in% surah87_o1$to) %>% select(from,to)
surah87_o3 = kedges %>% filter(from %in% surah87_o2$to) %>% select(from,to)
surah87_o4 = kedges %>% filter(from %in% surah87_o3$to) %>% select(from,to)
surah87_o5 = kedges %>% filter(from %in% surah87_o4$to) %>% select(from,to)
surah87_out = bind_rows(surah87_o1,surah87_o2,surah87_o3,surah87_o4,surah87_o5)

ala_intxt = quran_en_sahih %>% filter(ayah_title %in% 
                            c(surah87n_l5$from,surah87n_l5$to)) %>% pull(text)
ala_outxt = quran_en_sahih %>% filter(ayah_title %in% 
                                        c(surah87_out$from,surah87_out$to)) %>% pull(text)
## clean the texts
alain = tolower(ala_intxt)
alain = gsub("[^[:alnum:]\\-\\.\\s]", " ", alain)
alain = gsub("\\.", "", alain)
alain= trimws(alain)
## 1. tokenize
alain_ktoks = space_tokenizer(alain)
alain_itktoks = itoken(alain_ktoks, n_chunks = 10L)
stopw = stop_words$word
## 2. create vocabulary
alain_kvocab = create_vocabulary(alain_itktoks, stopwords = stopw)
## 3. vectorize the vocabulary
alain_k2vec = vocab_vectorizer(alain_kvocab)
## 4. create the tcm
alain_ktcm = create_tcm(alain_itktoks, alain_k2vec, skip_grams_window = 5L)
## 5. generate the Global Vector with rank = 50L
alain_kglove = GlobalVectors$new(rank = 50, x_max = 6)
## 6. Fit the GloVE model
alain_wv_main = alain_kglove$fit_transform(alain_ktcm, n_iter = 20)
## Use the model for prediction
alain_wv_context = alain_kglove$components
## This is in data.table format
alain_word_vec = alain_wv_main + t(alain_wv_context)

topic0 = alain_word_vec["allah",,drop = FALSE] 
topic00 = alain_word_vec["lord",,drop = FALSE] 
topic1 = alain_word_vec["living",,drop = FALSE] 
topic2 = alain_word_vec["dying",,drop = FALSE] 
topic3 = alain_word_vec["purify",,drop = FALSE] 
topic4 = alain_word_vec["hell",,drop = FALSE] 

topic5 = alain_word_vec["allah",,drop = FALSE] + 
  alain_word_vec["lord",,drop = FALSE] +
  alain_word_vec["living",,drop = FALSE] + 
  alain_word_vec["dying",,drop = FALSE] + 
  alain_word_vec["purify",,drop = FALSE] +
  alain_word_vec["hell",,drop = FALSE] 

t0_sim = sim2(x = alain_word_vec, y = topic0, method = "cosine")
htin0 = names(head(sort(t0_sim[,1], decreasing = T),7))
t00_sim = sim2(x = alain_word_vec, y = topic00, method = "cosine")
htin00 = names(head(sort(t00_sim[,1], decreasing = T),7))
t1_sim = sim2(x = alain_word_vec, y = topic1, method = "cosine")
htin1 = names(head(sort(t1_sim[,1], decreasing = T),7))
t2_sim = sim2(x = alain_word_vec, y = topic2, method = "cosine")
htin2 = names(head(sort(t2_sim[,1], decreasing = T),7))
t3_sim = sim2(x = alain_word_vec, y = topic3, method = "cosine")
htin3 = names(head(sort(t3_sim[,1], decreasing = T),7))
t4_sim = sim2(x = alain_word_vec, y = topic4, method = "cosine")
htin4 = names(head(sort(t4_sim[,1], decreasing = T),7))
t5_sim = sim2(x = alain_word_vec, y = topic5, method = "cosine")
htin5 = names(head(sort(t5_sim[,1], decreasing = T),7))

## clean the texts
alain = tolower(ala_outxt)
alain = gsub("[^[:alnum:]\\-\\.\\s]", " ", alain)
alain = gsub("\\.", "", alain)
alain= trimws(alain)
## 1. tokenize
alain_ktoks = space_tokenizer(alain)
alain_itktoks = itoken(alain_ktoks, n_chunks = 10L)
stopw = stop_words$word
## 2. create vocabulary
alain_kvocab = create_vocabulary(alain_itktoks, stopwords = stopw)
## 3. vectorize the vocabulary
alain_k2vec = vocab_vectorizer(alain_kvocab)
## 4. create the tcm
alain_ktcm = create_tcm(alain_itktoks, alain_k2vec, skip_grams_window = 5L)
## 5. generate the Global Vector with rank = 50L
alain_kglove = GlobalVectors$new(rank = 50, x_max = 6)
## 6. Fit the GloVE model
alain_wv_main = alain_kglove$fit_transform(alain_ktcm, n_iter = 20)
## Use the model for prediction
alain_wv_context = alain_kglove$components
## This is in data.table format
alain_word_vec = alain_wv_main + t(alain_wv_context)

topic0 = alain_word_vec["allah",,drop = FALSE] 
topic00 = alain_word_vec["lord",,drop = FALSE] 
topic1 = alain_word_vec["living",,drop = FALSE] 
topic2 = alain_word_vec["dying",,drop = FALSE] 
topic3 = alain_word_vec["purify",,drop = FALSE] 
topic4 = alain_word_vec["hell",,drop = FALSE] 

topic5 = alain_word_vec["allah",,drop = FALSE] + 
  alain_word_vec["lord",,drop = FALSE] +
  alain_word_vec["living",,drop = FALSE] + 
  alain_word_vec["dying",,drop = FALSE] + 
  alain_word_vec["purify",,drop = FALSE] +
  alain_word_vec["hell",,drop = FALSE] 

t0_sim = sim2(x = alain_word_vec, y = topic0, method = "cosine")
htout0 = names(head(sort(t0_sim[,1], decreasing = T),7))
t00_sim = sim2(x = alain_word_vec, y = topic00, method = "cosine")
htout00 = names(head(sort(t00_sim[,1], decreasing = T),7))
t1_sim = sim2(x = alain_word_vec, y = topic1, method = "cosine")
htout1 = names(head(sort(t1_sim[,1], decreasing = T),7))
t2_sim = sim2(x = alain_word_vec, y = topic2, method = "cosine")
htout2 = names(head(sort(t2_sim[,1], decreasing = T),7))
t3_sim = sim2(x = alain_word_vec, y = topic3, method = "cosine")
htout3 = names(head(sort(t3_sim[,1], decreasing = T),7))
t4_sim = sim2(x = alain_word_vec, y = topic4, method = "cosine")
htout4 = names(head(sort(t4_sim[,1], decreasing = T),7))
t5_sim = sim2(x = alain_word_vec, y = topic5, method = "cosine")
htout5 = names(head(sort(t5_sim[,1], decreasing = T),7))

## clean the texts
ala_ctext = c(ala_intxt,ala_outxt)
alain = tolower(ala_ctext)
alain = gsub("[^[:alnum:]\\-\\.\\s]", " ", alain)
alain = gsub("\\.", "", alain)
alain= trimws(alain)
## 1. tokenize
alain_ktoks = space_tokenizer(alain)
alain_itktoks = itoken(alain_ktoks, n_chunks = 10L)
stopw = stop_words$word
## 2. create vocabulary
alain_kvocab = create_vocabulary(alain_itktoks, stopwords = stopw)
## 3. vectorize the vocabulary
alain_k2vec = vocab_vectorizer(alain_kvocab)
## 4. create the tcm
alain_ktcm = create_tcm(alain_itktoks, alain_k2vec, skip_grams_window = 5L)
## 5. generate the Global Vector with rank = 50L
alain_kglove = GlobalVectors$new(rank = 50, x_max = 6)
## 6. Fit the GloVE model
alain_wv_main = alain_kglove$fit_transform(alain_ktcm, n_iter = 20)
## Use the model for prediction
alain_wv_context = alain_kglove$components
## This is in data.table format
alain_word_vec = alain_wv_main + t(alain_wv_context)

topic0 = alain_word_vec["allah",,drop = FALSE] 
topic00 = alain_word_vec["lord",,drop = FALSE] 
topic1 = alain_word_vec["living",,drop = FALSE] 
topic2 = alain_word_vec["dying",,drop = FALSE] 
topic3 = alain_word_vec["purify",,drop = FALSE] 
topic4 = alain_word_vec["hell",,drop = FALSE] 

topic5 = alain_word_vec["allah",,drop = FALSE] + 
  alain_word_vec["lord",,drop = FALSE] +
  alain_word_vec["living",,drop = FALSE] + 
  alain_word_vec["dying",,drop = FALSE] + 
  alain_word_vec["purify",,drop = FALSE] +
  alain_word_vec["hell",,drop = FALSE] 

t0_sim = sim2(x = alain_word_vec, y = topic0, method = "cosine")
htino0 = names(head(sort(t0_sim[,1], decreasing = T),7))
t00_sim = sim2(x = alain_word_vec, y = topic00, method = "cosine")
htino00 = names(head(sort(t00_sim[,1], decreasing = T),7))
t1_sim = sim2(x = alain_word_vec, y = topic1, method = "cosine")
htino1 = names(head(sort(t1_sim[,1], decreasing = T),7))
t2_sim = sim2(x = alain_word_vec, y = topic2, method = "cosine")
htino2 = names(head(sort(t2_sim[,1], decreasing = T),7))
t3_sim = sim2(x = alain_word_vec, y = topic3, method = "cosine")
htino3 = names(head(sort(t3_sim[,1], decreasing = T),7))
t4_sim = sim2(x = alain_word_vec, y = topic4, method = "cosine")
htino4 = names(head(sort(t4_sim[,1], decreasing = T),7))
t5_sim = sim2(x = alain_word_vec, y = topic5, method = "cosine")
htino5 = names(head(sort(t5_sim[,1], decreasing = T),7))

