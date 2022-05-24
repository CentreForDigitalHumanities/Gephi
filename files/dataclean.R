# cleaning Twitter dataset
library(tidyverse)

# Set to the file path where your data is stored.
setwd("C:/Users/bge_j/Documents/UDS/Living Lab network workshop")

# Load in your CSV file
dfraw <- read.csv("Data/data.csv")

# View the column names (metadata) that is included in the file. 
# Select the columns that are relevant to you. 
colnames(dfraw)

dfselect <- dfraw %>%
  select(created_at, author.username, author.description, text,
         public_metrics.like_count, author.public_metrics.followers_count, author.public_metrics.following_count, retweeted_user_id, entities.urls)

# Extract URLs from the entities.urls column, simplify them to their domain.
df_url <- dfselect
url_pattern <- 'http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+'

df_url$URL <- str_extract_all(df_url$entities.urls, url_pattern)
df_url$URL <- df_url$URL %>% as.character(unlist(df_url$URL)) 
df_url$URL <- word(df_url$URL,start=2,sep=" ")
df_url$URL <- str_extract_all(df_url$URL, url_pattern) %>% as.character() %>%
  gsub("\\\\|,","",.)

df_url <- df_url %>% select(-entities.urls)

library(urltools)

df_url$URL_domain <- df_url$URL %>% domain() %>% 
  str_replace("www.|nl.","")

write.table(df_url, "Data/data_clean.csv", na = "", sep = ";", row.names = FALSE)

# Retweet network
# Extract retweets through the retweeted_user_id column.
library(rtweet)
rtweet.retryonratelimit = TRUE

df_rt <- df_url %>%
  select(author.username,text,retweeted_user_id)
df_rt <- df_rt[!(is.na(df_rt$retweeted_user_id) | df_rt$retweeted_user_id==""),]

rts <- get_user_profile(df_rt$retweeted_user_id, bearer_token = get_bearer()) %>%
  select(username,id)

rts <- lookup_users(df_rt$retweeted_user_id)
rt <- rts %>% select(screen_name, user_id) %>% rename(retweeted_user_id = user_id, RT_username = screen_name)

# Convert the retweets into a Gephi edges file.
df_rt_gephi <- merge(rt,df_rt)

df_rt_gephi <- df_rt_gephi %>%
  rename(Source = author.username, Target = RT_username) %>%
  select(Source,Target)

View(df_rt_gephi)

write.table(df_rt_gephi, "Data/edges_retweets.csv", sep=";", col.names = TRUE, row.names = FALSE)

# Make a Gephi nodes table.
df_nodes <- dfselect %>%
  select(author.username, author.description, author.public_metrics.followers_count, author.public_metrics.following_count) %>%
  rename(Id = author.username)
  
df_nodes$Label <- df_nodes$Id
df_nodes <- df_nodes %>% distinct(Id, .keep_all = TRUE)

write.table(df_nodes, "Data/nodes.csv", sep=";", col.names = TRUE, row.names = FALSE)

# Now load your nodes and edges table into Gephi.
