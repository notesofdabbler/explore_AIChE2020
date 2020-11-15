
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)
library(tidytext)
library(tm)
library(topicmodels)

# read abstracts
talks_df = read.csv("scraped_results/talks.csv", stringsAsFactors = FALSE)

talks_df = talks_df %>% mutate(talkid = seq(1, nrow(talks_df)))

talks_df2 = talks_df %>% select(talkid, title) %>%
                unnest_tokens(word, title)

data(stop_words)
talks_df2 <- talks_df2 %>%
  anti_join(stop_words)

talks_df2 = talks_df2 %>% filter(!(word %in% c("00", "8", "7", "9", "author")))

talks_df3 = talks_df2 %>% group_by(talkid, word) %>% summarize(count = n())

talks_dtm = talks_df3 %>% cast_dtm(talkid, word, count)

talks_lda <- LDA(talks_dtm, k = 20, control = list(seed = 1234))

talks_topics <- tidy(talks_lda, matrix = "beta")

talks_top_terms <- talks_topics %>%
  group_by(topic) %>%
  top_n(10, beta) %>%
  ungroup() %>%
  arrange(topic, -beta)

talks_top_terms %>%
  mutate(term = reorder_within(term, beta, topic)) %>%
  ggplot(aes(beta, term, fill = factor(topic))) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~ topic, scales = "free") +
  scale_y_reordered()

talks_documents <- tidy(talks_lda, matrix = "gamma") %>% arrange(document, desc(gamma))

talks_doc2 = talks_documents %>% group_by(document) %>% slice(1) %>%
                 mutate(talkid = as.numeric(document)) %>% ungroup()

talks_df_topic = inner_join(talks_df, talks_doc2 %>% select(-document),
                           by = "talkid")
talks_df_topic %>% count(topic)

talks_df_topic %>% filter(topic == 8) %>% arrange(desc(gamma)) %>% select(title) %>% head(10)
