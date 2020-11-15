
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)
library(tidytext)
library(tm)
library(topicmodels)

# read abstracts
abs_df = read.csv("scraped_results/talk_abstracts.csv", stringsAsFactors = FALSE)

abs_df = abs_df %>% mutate(absid = seq(1, nrow(abs_df)))

abs_df2 = abs_df %>% select(absid, abstract) %>%
                unnest_tokens(word, abstract)

data(stop_words)
abs_df2 <- abs_df2 %>%
  anti_join(stop_words)

abs_df3 = abs_df2 %>% group_by(absid, word) %>% summarize(count = n())

abs_dtm = abs_df3 %>% cast_dtm(absid, word, count)

abs_lda <- LDA(abs_dtm, k = 20, control = list(seed = 1234))

abs_topics <- tidy(abs_lda, matrix = "beta")

abs_top_terms <- abs_topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

abs_top_terms %>%
  mutate(term = reorder_within(term, beta, topic)) %>%
  ggplot(aes(beta, term, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  scale_y_reordered()

abs_documents <- tidy(abs_lda, matrix = "gamma") %>% arrange(document, desc(gamma))

abs_doc2 = abs_documents %>% group_by(document) %>% slice(1) %>%
                 mutate(absid = as.numeric(document)) %>% ungroup()

abs_df_topic = inner_join(abs_df, abs_doc2 %>% select(-document),
                           by = "absid")
