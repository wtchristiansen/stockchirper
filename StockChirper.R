if(!requireNamespace("rtweet", quietly = TRUE)) install.packages("rtweet")
if(!requireNamespace("tidytext", quietly = TRUE)) install.packages("tidytext")
if(!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if(!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")
if(!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if(!requireNamespace("stringr", quietly = TRUE)) install.packages("stringr")

library(stringr)
library(rtweet)
library(tidytext)
library(dplyr)
library(lubridate)
library(ggplot2)

# Authenticate with Twitter API (you'll need to replace with your own keys)

# you now need a pretty expensive plan to get this data, maybe someday

create_token(
  app = "",
  consumer_key = "",
  consumer_secret = "",
  access_token = "",
  access_secret = ""
)

# check API connection
token <-auth_get()
print(token)

# test API w/broad query
test_tweets <- search_tweets("#technology", n = 100, include_rts = FALSE)

### USING STOCK SYMBOL ###

# Define the stock or hashtag you want to analyze
stock_symbol <- "#AAPL"

# Calculate the date for 3 months ago from today
since_date <- as.character(Sys.Date() - months(3))

# Search tweets related to the stock from the past 3 months
tweets_df <- search_tweets(stock_symbol, n = 100, include_rts = FALSE, since = since_date)

# Check data and sample if there are enough observations, determine if empty
if(nrow(tweets_df) > 0 && nrow(tweets_df) >= 500) {
  sampled_tweets <- sample_n(tweets_df, 500)
} else if (nrow(tweets_df) > 0) {
  # If the dataframe has fewer than 500 rows but is not empty
  sampled_tweets <- tweets_df
} else {
  # If the dataframe is empty, handle the case appropriately
  print("The dataframe is empty. No sampling can be performed.")
  # Handle the empty dataframe case, maybe set 'sampled_tweets' to NULL or an empty dataframe
  sampled_tweets <- NULL
}

# Clean and prepare the text data from the sampled tweets
tweets_text <- sampled_tweets %>%
  select(created_at, text) %>%
  mutate(date = as.Date(created_at)) %>%
  unnest_tokens(word, text)

# Load sentiment lexicon
nrc_lexicon <- get_sentiments("nrc")

# Perform sentiment analysis
tweets_sentiment <- tweets_text %>%
  inner_join(nrc_lexicon, by = "word") %>%
  group_by(date, sentiment) %>%
  summarise(count = n(), .groups = 'drop')select(created_at, text) %>%
  mutate(date = as.Date(created_at)) %>%
  unnest_tokens(word, text)

# Load sentiment lexicon
nrc_lexicon <- get_sentiments("nrc")

# Perform sentiment analysis
tweets_sentiment <- tweets_text %>%
  inner_join(nrc_lexicon, by = "word") %>%
  group_by(date, sentiment) %>%
  summarise(count = n(), .groups = 'drop')

# View the sentiment analysis results
print(tweets_sentiment)

#### visualize

sentiment_by_date <- tweets_sentiment %>%
  group_by(date, sentiment) %>%
  summarise(total_count = sum(count), .groups = 'drop')

# Convert date to Date class for proper plotting
sentiment_by_date$date <- as.Date(sentiment_by_date$date)

# Plotting the trend of sentiments over time
ggplot(sentiment_by_date, aes(x = date, y = total_count, color = sentiment)) +
  geom_line() +
  theme_minimal() +
  labs(title = "Trend of Sentiment over Time",
       x = "Date",
       y = "Total Sentiment Count",
       color = "Sentiment") +
  scale_color_manual(values = c("positive" = "green", "negative" = "red", "neutral" = "blue")) +
  theme(plot.title = element_text(size = 20, face = "bold"),
        axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 12))

# Note: Customize the colors and labels as needed

##########################

### USING KEYWORDS ###

keywords <- c("innovation", "technology")

# Create a search query string
query <- paste(keywords, collapse=" OR ")

# Fetch tweets (150 for test)
tweets_key <- search_tweets(
  q = query, 
  n = 150, 
  include_rts = FALSE, 
  lang = "en"
)

if(nrow(tweets_key) > 0 && nrow(tweets_key) >= 500) {
  sampled_tweets <- sample_n(tweets_key, 500)
} else if (nrow(tweets_key) > 0) {
  # If the dataframe has fewer than 500 rows but is not empty
  sampled_tweets <- tweets_key
} else {
  # If the dataframe is empty, handle the case appropriately
  print("The dataframe is empty. No sampling can be performed.")
  # Handle the empty dataframe case, maybe set 'sampled_tweets' to NULL or an empty dataframe
  sampled_tweets <- NULL
}

# Prepare text data
tweets_text <- tweets_key %>%
  select(status_id, text) %>%
  unnest_tokens(word, text)

# Load a sentiment lexicon
nrc_lexicon <- get_sentiments("nrc")

# Perform sentiment analysis
tweets_sentiment <- tweets_text %>%
  inner_join(nrc_lexicon, by = "word") %>%
  count(status_id, sentiment) %>%
  spread(sentiment, n, fill = 0) %>%
  # Optionally, add a row to summarize each tweet's overall sentiment
  mutate(overall_sentiment = positive - negative)

# Note: This code provides a basic sentiment analysis. You might need to adjust it based on your specific needs.

# Assuming 'created_at' is in 'tweets_with_keywords', convert to Date format
tweets_key$created_at <- as.Date(tweets_key$created_at)

# Join sentiment scores back to the original tweets to get dates
tweets_sentiment_with_date <- tweets_key %>%
  select(status_id, created_at) %>%
  inner_join(tweets_sentiment, by = "status_id")

# Aggregate overall sentiment by date
sentiment_over_time <- tweets_sentiment_with_date %>%
  group_by(created_at) %>%
  summarise(average_sentiment = mean(overall_sentiment))

# Plotting
ggplot(sentiment_over_time, aes(x = created_at, y = average_sentiment)) +
  geom_line() + # or geom_smooth() for a smoother trend line
  geom_point(aes(color = average_sentiment), size = 2) + 
  scale_color_gradient2(low = "red", high = "green", mid = "yellow", midpoint = 0) +
  theme_minimal() +
  labs(title = "Trend of Overall Sentiment Over Time",
       x = "Date",
       y = "Average Sentiment Score")