
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)

# read talks data
talks_df = read.csv("scraped_results/talks.csv", stringsAsFactors = FALSE)
# read authors and affiliation data
auth_df = read.csv("scraped_results/talk_authors.csv", stringsAsFactors = FALSE)
auth_df = auth_df %>% mutate(author = tolower(author), affil = tolower(affil))

affil_list = auth_df %>% distinct(affil)
affil_list = affil_list %>% mutate(affil_id = seq(1, nrow(affil_list)))

auth_df = inner_join(auth_df, affil_list, by = "affil")
# csv file was written and insitution names were manually cleaned
#write.csv(affil_list, "scraped_results/affil_list.csv", row.names = FALSE)

# read cleaned affiliation list
affil_cln = read.csv("scraped_results/affil_list_clean.csv", stringsAsFactors = FALSE)
auth_df = inner_join(auth_df, affil_cln %>% select(affil_id, affil_clean, univ), by = "affil_id")

# author - affiliation map
auth_affil_df = auth_df %>% distinct(author, affil)
auth_affil_df = auth_affil_df %>% group_by(author) %>% slice(1) %>% ungroup()

# author with high number of talks
top_auth = auth_df %>% count(author, sort = TRUE) %>% filter(n > 3)
top_auth = inner_join(top_auth, auth_affil_df, by = "author")

# institutions with high number of talks
talk_affil = auth_df %>% distinct(sessionid, talkid, affil) 
talk_affil %>% count(affil, sort = TRUE) %>% head(20)

# Explore industry university interaction
induniv = auth_df %>% distinct(sessionid, talkid, univ)
induniv_w = induniv %>% mutate(flag = 1) %>% 
        pivot_wider(names_from = univ, values_from = flag, values_fill = 0) %>%
        rename(ind = `0`, univ = `1`)
induniv_w = induniv_w %>% mutate(type = case_when(
                                           ind == 0 & univ == 1 ~ 'univ only',
                                           ind == 1 & univ == 0 ~ 'ind only',
                                           ind == 1 & univ == 1 ~ 'ind_univ'
                                             ))

induniv_w %>% count(ind, univ, type)

auth_df2 = inner_join(auth_df, induniv_w %>% select(sessionid, talkid, type), by = c("sessionid", "talkid"))


ind_df = auth_df2 %>% filter(type == "ind_univ", univ == 0) %>% 
             distinct(sessionid, talkid, affil_clean) 
univ_df = auth_df2 %>% filter(type == "ind_univ", univ == 1) %>% 
           distinct(sessionid, talkid, affil_clean) %>%
           rename(affil_clean_univ = affil_clean) 
ind_df = inner_join(ind_df, univ_df, by = c("sessionid", "talkid"))
ind_df2 = ind_df %>% 
          group_by(affil_clean, affil_clean_univ) %>% summarize(cnt = n())
ind_df2 = ind_df2 %>% ungroup() %>% group_by(affil_clean) %>% 
                 mutate(cnt = n()) %>% ungroup() %>% 
                 arrange(desc(cnt), affil_clean, affil_clean_univ)
ind_df2 = ind_df2 %>% filter(cnt >= 3)


