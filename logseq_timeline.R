---
output: html_document
runtime: shiny
---
  
# Load relevant packages  

library(shiny)
library(timevis)
library(tidyverse)
library(tools)

# Obtain list of markdown files in directory

files <- file.info(list.files(full.names = TRUE, recursive = TRUE, pattern = "*.md"))
files$path <- row.names(files)
files$filename <- basename(files$path)

# Build database of scheduled strings

scheduled_task_string <- "[\t]?-[^\x2d]+<[0-9a-zA-Z\x20\x2d]+>"

df <- data.frame(content = as.character())

for(i in 1:nrow(files)){
  x <- read_file(files$path[i])
  content <- unlist(str_extract_all(x, scheduled_task_string))
  content.df <- as.data.frame(content)
  df <- rbind(df, content.df)
}

# Create various functions for manipulating strings

remove_time_stamps <- function(x){ # removes time stamps
  return(str_replace_all(x, "[a-zA-Z]+::[\x20]+[0-9]+", ""))
}

remove_multiple_spaces <- function(x){ # Removes multiples spaaces
  return(str_replace_all(x, "[\x20]{2,10}", ""))
}

extract_date <- function(x){  # Extracts the date (i.e. returns a string with all characgers except date removed)
  return(str_extract(x, "[0-9]{4}-[0-9]{2}-[0-9]{2}"))
}

remove_dates <- function(x){ # removes dates
  return(str_replace(x, "[a-zA-Z]+:[\x20]<.+>", ""))
}

has_DONE <- function(x){ # Returns TRUE is task is marked "DONE"
  return(str_detect(x, "- DONE"))
}


remove_links <- function(x){ # Removes all links in a string
  return(str_replace(x, "\\[\\[.+\\]\\]", ""))
}

extract_links <- function(x){ # Extracts links (returns a string with all characters removed except links)
  result <- str_extract(x, "\\[\\[.+\\]\\]")
  result <- str_replace_all(result, "\\/[a-zA-Z\\/]+", "")
  return(result)
}

remove_dash <- function(x){ # removes dashes from a string
  return(str_replace(x, "^[^a-zA-Z]*", ""))
}

insert_regular_return_characters <- function(x){ # Adds a return character every four words
  words <- unlist(str_extract_all(x, "[^\x20]+")) # This prevents labels being too wide
  num_blocks <- as.integer(length(words)/4) # NB return once every four words
  if(num_blocks > 0){
  seq <- seq(4, num_blocks*4, 4)
  words[seq] <- str_replace_all(words[seq], "(.+)", "\\1<br>")
  }
  return(paste(words, collapse = " "))
}


today <- Sys.Date()

df %>%
  mutate(has_DONE = sapply(content, has_DONE)) %>%
  filter(has_DONE == FALSE) %>% 
  select(-has_DONE) -> df
df$content <- sapply(df$content, remove_time_stamps)
df$content <- sapply(df$content, remove_multiple_spaces)

df$start <- sapply(df$content, extract_date)

df$start <- as.Date(df$start)

df %>% filter(start >= (today-14)) -> df # Only shows events after two weeks ago

df$content <- sapply(df$content, remove_dates)
df$content <- sapply(df$content, remove_dash)
df$content <- sapply(df$content, insert_regular_return_characters)

df$end <- NA

df$groups <- sapply(df$content, extract_links)

groups <- df %>% select(groups)

# Uncoment this line if you want links removed from output.
# df$content <- sapply(df$content, remove_links) 

df$id = 1:nrow(df)

# Produce timelines as timeline.html file

ui <- fluidPage(
  timevisOutput("timeline")
)

server <- function(input, output, session) {
  output$timeline <- renderTimevis({
    timevis(df, options = list(editable = TRUE))
  })
  

}

shinyApp(ui = ui, server = server)





