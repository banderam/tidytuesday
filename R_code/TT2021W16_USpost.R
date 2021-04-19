# TidyTuesday, 2021 Week 16 - US Post Offices ----

# 01. Libraries ----
library(tidytuesdayR)
library(tidyverse)
library(maps)
library(gganimate)
library(ggthemes)

# 02. Read data ----
tuesdata <- tt_load(2021, week = 16)
tuesdata

# 03. Wrangling
post_offices <- tuesdata$post_offices %>% 
  filter(!state %in% c("AK", "HI"),
         !is.na(gnis_longitude) == TRUE | !is.na(gnis_latitude) == TRUE,
         !is.na(established) == TRUE & established > 1776) %>% 
  select(name,
         established,
         discontinued,
         long = gnis_longitude,
         lat  = gnis_latitude) %>% 
  mutate(discontinued = replace_na(discontinued, 2021),
         year = map2(established, discontinued, seq)) %>% 
  unnest(year) %>%
  filter(year < 2021)

# 04. Visualization ----
post_offices %>%
  
  filter(year > 1776 & year %% 2 == 0) %>% 
  
  # ggplot
  ggplot(aes(x = long, y = lat)) +
  geom_point(size = 0.2, alpha = 0.3, color = "#6494AA") + 
  
  # gganimate
  transition_manual(year) +
  
  # Foramtting
  labs(title = "A year-by-year snapshot of the US national postal system",
       subtitle = "Year: {current_frame}",
       caption = "Data: Harvard Dataverse | Mauro Bandera | Twitter: @bandera_mauro") +
  
  theme_map() +
  coord_map() +
  
  theme(plot.title = element_text(size = 15, face = "bold", color = "#6494AA"),
        plot.subtitle = element_text(size = 15, face = "bold", color = "#393D3F"),
        plot.caption = element_text(size = 11))

# 05. Save out ----
anim_save(animation = last_animation(), filename = "USpost.gif")

