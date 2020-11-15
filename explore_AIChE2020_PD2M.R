
library(dplyr)
library(tidyr)
library(ggplot2)
library(stringr)

# read talks data
talks_df = read.csv("scraped_results/talks.csv", stringsAsFactors = FALSE)

session_df = talks_df %>% distinct(sessionid, session)

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
auth_affil_df = auth_df %>% distinct(author, affil_clean)
auth_affil_df = auth_affil_df %>% group_by(author) %>% slice(1) %>% ungroup()

# author with high number of talks
top_auth = auth_df %>% count(author, sort = TRUE) %>% filter(n > 3)
top_auth = inner_join(top_auth, auth_affil_df, by = "author")
top_auth
write.csv(top_auth, "tables/top_auth.csv", row.names = FALSE)

# institutions with high number of talks
talk_affil = auth_df %>% distinct(sessionid, talkid, affil_clean) 
top_affil = talk_affil %>% count(affil_clean, sort = TRUE) %>% head(20)
top_affil
write.csv(top_affil, "tables/top_affil.csv", row.names = FALSE)

# Explore industry university interaction

# Find proportion of talks by industry, university and combination
induniv = auth_df %>% distinct(sessionid, talkid, univ)
induniv_w = induniv %>% mutate(flag = 1) %>% 
        pivot_wider(names_from = univ, values_from = flag, values_fill = 0) %>%
        rename(ind = `0`, univ = `1`)
induniv_w = induniv_w %>% mutate(type = case_when(
                                           ind == 0 & univ == 1 ~ 'univ only',
                                           ind == 1 & univ == 0 ~ 'ind only',
                                           ind == 1 & univ == 1 ~ 'ind_univ'
                                             ))

induniv_summ = induniv_w %>% count(ind, univ, type) %>% mutate(n_pct = n / sum(n))
write.csv(induniv_summ, "tables/induniv_summ.csv", row.names = FALSE)

# Find the specific collaborations between industry and university
auth_df2 = inner_join(auth_df, induniv_w %>% select(sessionid, talkid, type), by = c("sessionid", "talkid"))


ind_induniv_df = auth_df2 %>% filter(type == "ind_univ", univ == 0) %>% 
             distinct(sessionid, talkid, affil_clean) 
univ_induniv_df = auth_df2 %>% filter(type == "ind_univ", univ == 1) %>% 
           distinct(sessionid, talkid, affil_clean) %>%
           rename(affil_clean_univ = affil_clean) 
induniv_collab_df = inner_join(ind_induniv_df, univ_induniv_df, by = c("sessionid", "talkid"))
induniv_collab_df2 = induniv_collab_df %>% 
          group_by(affil_clean, affil_clean_univ) %>% summarize(cnt = n())
induniv_collab_df2 = induniv_collab_df2 %>% ungroup() %>% group_by(affil_clean) %>% 
                 mutate(cnt = n()) %>% ungroup() %>% 
                 arrange(desc(cnt), affil_clean, affil_clean_univ)
induniv_collab_df2 = induniv_collab_df2 %>% filter(cnt >= 3)
write.csv(induniv_collab_df2, "tables/induniv_collab.csv", row.names = FALSE)

session_mix_df = auth_df2 %>% distinct(sessionid, talkid, type) %>%
                          count(sessionid, type) %>%
                          group_by(sessionid) %>% mutate(n_pct = n / sum(n)) %>%
                          ungroup()
session_mix_df_w = session_mix_df %>% select(-n) %>%
                       pivot_wider(names_from = type, values_from = n_pct, values_fill = 0)

sort_ind = session_mix_df_w %>% arrange(`univ only`)
sort_ind = inner_join(sort_ind %>% select(sessionid, `univ only`), session_df, by = "sessionid")
sort_ind = inner_join(sort_ind,
                      talks_df %>% distinct(sessionid, session_url),
                      by = "sessionid")
write.csv(sort_ind, "tables/sort_ind.csv",row.names = FALSE)
