# Source: http://varianceexplained.org/r/love-actually-network/

library(tidyverse)

raw <- read_lines(here::here("14-visualize-text", "data/love-actually-raw.txt"))

love_actually <- tibble(raw = raw) %>%
  filter(raw != "", !str_detect(raw, "(song)")) %>%
  mutate(
    is_scene = str_detect(raw, " Scene "),
    scene = cumsum(is_scene)
  ) %>%
  filter(!is_scene) %>%
  separate(raw, c("speaker", "dialogue"), sep = ":", fill = "left") %>%
  group_by(scene, line = cumsum(!is.na(speaker))) %>%
  summarize(speaker = speaker[1], dialogue = str_c(dialogue, collapse = " "))

write_csv(love_actually, here::here("14-visualize-text", "data/love-actually.csv"))

cast <- read_csv(here::here("14-visualize-text", "data/love_actually_cast.csv"))

love_actually <- love_actually %>%
  left_join(cast) %>%
  mutate(character = paste0(speaker, " (", actor, ")"))
