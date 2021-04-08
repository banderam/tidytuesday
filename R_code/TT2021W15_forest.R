# TidyTuesday, 2021 Week 15 - Deforestation ----

# 01. Libraries ----
library(tidytuesdayR)
library(tidyverse)
library(WDI)

# 02. Read data ----
tuesdata <- tt_load(2021, week = 15)

forest <- tuesdata$forest
WDI_pop_014 <- WDI(indicator = "SP.POP.0014.TO", start = 2000, end = 2015)


# 03. Wrangle data ---
df_014 <- forest %>% 
  
  # Consider only years from 2000
  filter(year != 1990) %>% 
  
  # Join forest and young population
  left_join(WDI_pop_014, by = c("entity" = "country", "year")) %>% 
  select(1:3,
         net_forest_conversion,
         pop_014 = SP.POP.0014.TO) %>% 
  
  # Data transformation
  # 1ha = 10000 sqm
  # Basketball court area = 436.64 sqm
  mutate(
    net_per_pop_sqm = net_forest_conversion * 10000 / pop_014,
    basketball_court = net_per_pop_sqm / 436.64
  ) %>% 
  
  arrange(desc(abs(net_per_pop_sqm))) %>%
  
  # Create label for plot
  mutate(label = paste0(entity, ", ", year))


# 04. Visualizaton ----
gg_014 <- df_014 %>% 
  
  # Preapare data and fct_reorder
  select(country = entity, basketball_court, label) %>% 
  slice_max(abs(basketball_court), n = 10) %>% 
  mutate(label = fct_reorder(label, basketball_court)) %>% 
  
  # Plot
  ggplot(aes(basketball_court, label, fill = basketball_court > 0)) +
  geom_col() +
  
  # Formatting
  scale_fill_manual(values = c("#D1C99F", "#3F612D")) +
  
  scale_x_continuous(name = "Basketball Courts (Equivalent Area)", limits = c(-5,4.5), breaks = c(-5,-4,-3,-2,-1,0,1,2,3,4)) + # to improve
  
  geom_label(aes(label = label), hjust = "outward", label.size = 0, fill = "white", size = 4) +
  
  labs(
    title = "Deforestation and young generations",
    subtitle = str_wrap(string = "In 2010, Australia afforested an equivalent area of 4 basketball courts, for every young citizen (0-14 years old). 
                        The same year, Paraguay deforested an equivalent area of nearly 5 basketball courts.",
                        width = 115), 
    caption = "Data: Our World in Data & data.worldbank.org | Twitter: @bandera_mauro") +
  
  # Theme
  theme(axis.text.x = element_text(size = 10), 
        axis.title.x = element_text(size = 11), 
        axis.text.y = element_blank(), 
        axis.ticks.y = element_blank(), 
        axis.title.y = element_blank(),
        legend.position = "none", 
        panel.background = element_blank(), 
        panel.grid = element_blank(),
        plot.title = element_text(size = 17, face = "bold"),
        plot.subtitle = element_text(size = 13, face = "italic"),
        plot.caption = element_text(size = 8))

 # 05. Save out 
 ggsave(plot = gg_014, filename = "deforestation.png",
        width = 15, height = 8, dpi = 150, units = "in", device = "png")
 
