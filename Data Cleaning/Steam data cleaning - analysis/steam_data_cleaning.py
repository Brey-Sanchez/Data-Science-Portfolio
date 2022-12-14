# -*- coding: utf-8 -*-
"""Steam data cleaning.ipynb

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/1VzzMfyVlk4dYx_DjhpEXr2QXLHFRUTmj
"""

import pandas as pd

# Importing the json file with the correct formart
steam_games = pd.read_json('/content/steam_games.json', 
                           orient='index').reset_index(drop='True')

steam_games.head()

# Checking datatypes
steam_games.dtypes

# Checking datatypes with a bit more detail
steam_games.apply(lambda x: type(x[0]))

# Checking for nulls/NAs in any of the columns
steam_games.isnull().sum()

# Checking empty cells
steam_games.apply(lambda x: x == '').sum()

# Describing all numeric columns
steam_games.describe()

# There should be no duplicates in the appid column
steam_games['appid'].duplicated().sum()

# There could be duplicate names
steam_games['name'].duplicated().sum()

# Prices are missing the decimal separator
def correct_prices(price):
  if price != 0:
    price = str(price)
    price = price[:-2] + '.' + price[-2:]

  return float(price)

# Applying the fix to both prices columns
steam_games['price'] = steam_games['price'].apply(correct_prices)
steam_games['initialprice'] = steam_games['initialprice'].apply(correct_prices)

# Changes needed:
# Change MA 15+ to 15
# 7+ to 7, 21+ to 21
# 180 to 18
steam_games.required_age.value_counts()

steam_games.loc[steam_games.required_age == '180', 'required_age'] = '18'

# Extracting only the digits
steam_games['required_age'] = steam_games['required_age'].astype('str').str.extract('(\d+)').astype('int64')

# The release_date column should be of the datetime type
steam_games['release_date'] = pd.to_datetime(steam_games['release_date'], format='%Y/%m/%d')

# Checking for the range of dates
steam_games.release_date.describe(datetime_is_numeric=True)

# It seems that these games don't have a public release date
steam_games.loc[steam_games['release_date'].isnull(), :].head()

# Extracting the number of minimun and maximun estimated owners for each game
steam_games['min_est_owners'] = steam_games['owners'].apply(lambda x: int(x.split(' .. ')[0].replace(',', '')))
steam_games['max_est_owners'] = steam_games['owners'].apply(lambda x: int(x.split(' .. ')[1].replace(',', '')))

# Making sure that the columns have been created correctly
steam_games.loc[:5, ['owners', 'min_est_owners', 'max_est_owners']]

pd.set_option('display.max_columns', None)
steam_games.head()

# Creating new columns for each OS so we can quickly check if a game is
# for a specific platform
steam_games = steam_games.join(steam_games['platforms'].apply(pd.Series), 
                               how='left')

steam_games.head()

# Dropping unnecessary columns
steam_games.drop(columns=['owners', 'platforms'], inplace=True)

# Calculating the total number of reviews and the percentage of all reviews that
# are positive
steam_games['total_reviews'] = (steam_games['positive'] + steam_games['negative'])

steam_games['perc_positive_reviews'] = (steam_games['positive'] / steam_games['total_reviews']) * 100

steam_games.loc[:5, ['positive', 'negative', 'perc_positive_reviews']]

# Checking the distribution of the rating column
steam_games['perc_positive_reviews'].describe()

# Top 10 games with highest rating among those with more than 10.000 reviews
steam_games.loc[steam_games['total_reviews'] > 10000, 
                ['name', 'perc_positive_reviews']].\
                nlargest(10, 'perc_positive_reviews')

# Getting a count of all genres
genres_count = dict()

for genre_list in steam_games.genre:
  for genre in genre_list.split(', '):
    if genre != '':
      if genre not in genres_count:
        genres_count[genre] = 1
      else:
        genres_count[genre] += 1

genres_count

# Top 10 most popular genres
pd.Series(genres_count).nlargest(10)

# Getting a count of all tags in the dataset
tags_dict = {}

for tag_dict in steam_games['tags']:
  for key in tag_dict.keys():
    if key not in tags_dict:
      tags_dict[key] = 1
    else:
      tags_dict[key] += 1

pd.Series(tags_dict).sort_values(ascending=False)

import matplotlib.pyplot as plt
from matplotlib.pyplot import figure
import seaborn as sns

# Getting the data in the correct format to obtain the percentage of games
# that are available for each OS
os_df = steam_games[['name', 'windows', 'mac', 'linux']]

os_df = pd.melt(os_df, id_vars='name', value_vars=['windows', 'mac', 'linux'], var_name='os',
                value_name='available')

os_df.head()

os_grouped = os_df.groupby('os').agg(perc_available=('available', 
                                     lambda x: sum(x)/len(x))).reset_index()

os_grouped

# % of games available for each OS
figure(figsize=(10, 8), dpi=100)

sns.set_style('darkgrid')

sns.barplot(data=os_grouped, x='os', y='perc_available',
            order=['windows', 'mac', 'linux'])

plt.title('Percentage of games that are available on each OS')
plt.xlabel('OS')
plt.ylabel('% of games available')

ticks = [x/100 for x in range(0, 125, 25)]

plt.yticks(ticks=ticks,
           labels=[str(int(x * 100)) + ' %' for x in ticks])

plt.show()

# Filtering on the initial price column to check the distribution of prices
# for games that cost 80 dollars or less
no_price_outlier = steam_games[steam_games.initialprice <= 80]

# A kernel density estimation makes it easier to see the underlying distribution,
# as a histogram would be too messy with so much data
f, ax = plt.subplots(figsize=(10, 8), dpi=100)

sns.kdeplot(data=no_price_outlier, x='initialprice', fill=True, ax=ax,
            bw_adjust=1.5)

plt.xlim((0, 80))

plt.xlabel('Launch price ($)')
plt.title('Distribution of price')

plt.show()

# Bivariate distribution of price and rating for games that have more than
# 100 reviews and cost 80 dollars or less
sns.set_style('darkgrid')

more_100_rat = steam_games.loc[(steam_games['total_reviews'] > 100) &
                               (steam_games['initialprice'] <= 80), :]

figure, ax = plt.subplots(figsize=(10, 8), dpi=100)

sns.histplot(data=more_100_rat, x='initialprice', y='perc_positive_reviews',
             cbar=True, binwidth=(5,5), binrange=[(0, 80), (0, 100)],
             stat='count', ax=ax, cbar_kws={'label': 'Number of games'})

sns.regplot(data=more_100_rat, x='initialprice', y='perc_positive_reviews',
            scatter=False, ax=ax, color='red')

plt.yticks(ticks=[x for x in range(5, 105, 5)])
plt.ylim((0, 100))
plt.xticks(ticks=[x for x in range(0, 85, 5)])
plt.xlim((0, 80))

plt.xlabel('Price at launch ($)')
plt.ylabel('% of positive ratings')

_ = plt.show()

# Creating custom categories for prices of games
steam_games['price_cat'] = pd.cut(steam_games.initialprice, 
                                  bins=[-1, 0, 20, 40, 60, steam_games.initialprice.max()],
                                  labels=['Free', 'Cheap', 'Normal', 'Expensive', 'Very Expensive'], 
                                  include_lowest=True)

steam_games.price_cat.unique()

import numpy as np

# Relationship between price category and number of owners
price_owners = steam_games.groupby('price_cat').agg(avg_owners=('min_est_owners', np.mean)).reset_index()

# One might expect that, the lower the price, the higher the number of owners.
# Let's check that assumption
figure, ax = plt.subplots(figsize=(10, 8), dpi=100)

sns.barplot(data=price_owners, x='price_cat', y='avg_owners', color='indigo')

ticks = [x for x in range(0, 600000, 100000)]
plt.yticks(ticks=ticks,
           labels=[f'{x:,}' for x in ticks])

plt.ylabel('Average number of owners')
plt.xlabel('Price category')

plt.show()

# We are now going to analyze the evolution of the average price and average
# rating of games per year. Games with more than 100 reviews
import datetime as dt
import numpy as np

steam_games['year'] = steam_games.release_date.dt.strftime('%Y')

steam_games_filt = steam_games.loc[(steam_games['release_date'].notnull()) &
                                   (steam_games['total_reviews'] > 100), :]

# Grouping by year and calculating the averages for price and rating
month_year = steam_games_filt.groupby('year').agg(avg_price=('initialprice', np.mean),
                                                  avg_rating=('perc_positive_reviews', np.mean),
                                                  n_games=('appid', len),).\
                                                  reset_index()

month_year = month_year.loc[month_year['n_games'] >= 50, :]

month_year.sort_values('year', inplace=True)

month_year

# Evolution of rating and concurrent users for games based on price category

figure, ax = plt.subplots(figsize=(10, 8), dpi=100)

sns.lineplot(data=month_year, x='year', y='avg_price',
             label='Average price')

plt.legend(bbox_to_anchor=(0.992, 1))

sns.pointplot(data=month_year, x='year', y='avg_price',
              color='blue')

plt.ylabel('Average price of games ($)')
plt.xlabel('Year')
plt.ylim((0, 30))

plt.xticks(fontsize=10)

ax2 = plt.twinx()

sns.lineplot(data=month_year, x='year', y='avg_rating', ax=ax2,
             color='red', label='Average rating')

sns.pointplot(data=month_year, x='year', y='avg_rating', ax=ax2,
              color='red')

plt.legend(bbox_to_anchor=(1, 0.95))

plt.title('Evolution of price and rating of games by year')
plt.ylabel('Average rating (% of reviews that are positive)')
plt.ylim((0, 100))

plt.show()