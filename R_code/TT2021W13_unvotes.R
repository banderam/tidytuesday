# TidyTuesday, 2021 Week 13 - UN Votes Dataset ----

# 01. Libraries ----
library(tidytuesdayR)
library(tidyverse)


# 02. Read data ----
tuesdata <- tt_load(2021, week = 13)

unvotes <- tuesdata$unvotes
roll_calls <- tuesdata$roll_calls
issues <- tuesdata$issues


# 03. Wrangle data ----

# Create a tbl with all rcids with lone votes
rcid_lone <- unvotes %>% 
  
  group_by(rcid) %>% 
  filter(sum(vote == "no") == 1) %>%
  ungroup() %>% 
  distinct(rcid)

# Create a tbl with count of votes by country
votes_by_country <- unvotes %>% 
  count(country, sort = TRUE)

# Join dataframes and prepare data for visualisation
lone_votes_cty <- rcid_lone %>% 
  
  # Join unvotes to retrieve country names
  left_join(unvotes, by = "rcid") %>%
  
  # Filter only countries with 'no' votes
  filter(vote == "no") %>%              
  select(rcid, country) %>% 
  
  # Join issue
  # NOTE: issues does not contains unique rcids. This join will increase the count of votes.
  left_join(issues, by = "rcid") %>% 
  mutate(issue = replace_na(issue, "Unknown")) %>%
  
  select(rcid, country) %>% 
  count(country, sort = TRUE) %>% 
  
  # Join votes_by country for pct calculation
  left_join(votes_by_country, by = "country") %>% 
  rename(
    lone_votes = n.x,
    total_votes = n.y
  ) %>% 
  
  # fct_lump to create 'Other Countries' after top_10 in rank
  mutate(country = as_factor(country) %>% fct_lump(n = 10, w = lone_votes, other_level = "Other Countries")) %>%
  
  # group_by and summarize 'Other Countries'
  group_by(country) %>% 
  summarise(
    lone_votes = sum(lone_votes),
    total_votes = sum(total_votes)
  ) %>% 
  ungroup() %>% 
  
  # Add pct of lone votes over total votes
  mutate(pct_lone_votes = lone_votes/total_votes) %>% 
  
  # fct_reorder and fct_relevel for charting purposes
  mutate(country = country %>% fct_reorder(lone_votes)) %>% 
  mutate(country = country %>% fct_relevel("Other Countries", after = 0)) %>% 
  
  # Create labels for plot
  mutate(pct_text = scales::percent(pct_lone_votes, accuracy = 0.01)) %>% 
  
  mutate(rank = row_number()) %>% 
  mutate(rank = case_when(
    rank == max(rank) ~ NA_integer_,
    TRUE ~ rank
  )) %>% 
  
  mutate(label_text = str_glue("Rank: {rank}\nLone Votes: {lone_votes}\nPct of Total Votes: {pct_text}"))


# 04. Visualisation ----

plot <- lone_votes_cty %>% 
  
  ggplot(aes(lone_votes, country)) +
  geom_segment(aes(xend = 0, yend = country), size = 1.5, color = "#3E92CC") +
  geom_point(size = 4, color = "#3E92CC") +
  
  # Add labels
  geom_label(aes(label = label_text), 
             size = 2, hjust = "inward") +
  
  # Formatting
  scale_x_continuous(expand = c(0,5)) +
  
  labs(
    title = "Lone Votes against UN Resolutions",
    subtitle = "Ranking of countries that voted against the UN Assembly",
    x = "Number of Lone Votes",
    y = "", 
    caption = "Source: Harvard's dataverse | Mauro Bandera | Twitter: @bandera_mauro"
  ) +
  
  # Theme
  theme_minimal() +
  theme(
    plot.title = element_text(family = "Tahoma", face = "bold"), 
    plot.caption = element_text(face = "italic", family = "Tahoma"), 
    plot.subtitle = element_text(face = "italic", family = "Tahoma"),
    axis.text.y = element_text(family = "Tahoma"), 
    axis.title.x = element_text(size = 8, family = "Tahoma"), 
    axis.text.x = element_text(size = 8, family = "Tahoma")
  )


# 05. Save out ----
plot %>% ggsave(
  filename = "unvotes.png",
  device = "png")
