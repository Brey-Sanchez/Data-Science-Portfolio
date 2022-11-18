library(tidyverse)

nba_shots <- read_csv('C:\\Users\\ter1\\Downloads\\NBA shots\\NBA_04_22_Shots.csv')

# Checking datatypes and structure of the dataset

str(nba_shots)

# Checking for nulls

map(nba_shots, function(x) sum(is_null(x)))

# Checking for NAs as well

map(nba_shots, function(x) sum(is.na(x)))

# Players who don't have a position

no_position <- nba_shots %>%
  filter(is.na(groupPosition)) %>%
  select(namePlayer) %>%
  unique()

no_position

# Replacing old team names to make sure that there are only 30 teams for
# convenience in plots

length(unique(nba_shots$nameTeam))

unique(nba_shots$nameTeam)

nba_shots <- nba_shots %>%
  mutate(nameTeam = case_when(
    nameTeam == "New Jersey Nets" ~ "Brooklyn Nets",
    nameTeam == "Charlotte Bobcats" ~ "Charlotte Hornets",
    nameTeam == "New Orleans Hornets" ~ "New Orleans Pelicans",
    nameTeam == "New Orleans/Oklahoma City Hornets" ~ "New Orleans Pelicans",
    nameTeam == "LA Clippers" ~ "Los Angeles Clippers",
    nameTeam == "Seattle SuperSonics" ~ "Oklahoma City Thunder",
    TRUE ~ nameTeam
  ))

# There should be only 30 teams now

length(unique(nba_shots$nameTeam))

# Distribution of the distance of shots taken

ggplot(data = nba_shots, aes(x = distanceShot)) +
  geom_histogram() +
  xlab("Distance in feet") +
  ylab("Number of shots") +
  theme_minimal()

# Percentage of games that went to overtime

perc_overtime <- nba_shots %>%
  group_by(idGame)  %>%
  summarise(maxPeriod = max(numberPeriod)) %>%
  mutate(overtime = maxPeriod > 4) %>%
  group_by(overtime) %>%
  summarise(perc = n() / length(unique(nba_shots$idGame))) %>%
  mutate(perc = round(perc * 100, 2))

perc_overtime

# Only around 6% of the games went to overtime

# Best corner 3 shooters with more than 500 shots

corner_3 <- nba_shots %>%
  filter(zoneBasic %in% c( "Left Corner 3", "Right Corner 3")) %>%
  group_by(namePlayer) %>%
  summarise(n_shots = n(),
            perc_made = sum(isShotMade) / n(),
            att_per_game = n() / length(unique(idGame))) %>%
  filter(n_shots > 500) %>%
  arrange(desc(n_shots))

ggplot(data = corner_3, aes(x = n_shots, y = perc_made, label = namePlayer)) +
  geom_point() +
  geom_text(check_overlap = TRUE, size = 3, nudge_y = 0.005) +
  xlab("Number of shots") +
  ylab("% made") +
  ggtitle("Corner 3 specialists") +
  theme_minimal()

# Let's explore shot labels, as they are known for not being reliable. Usually
# made shots have a larger description, so let's try to confirm that theory

shot_desc <- nba_shots %>%
  group_by(typeAction) %>%
  summarise(perc_made = sum(isShotMade) / n(),
            n_shots = n()) %>%
  mutate(n_words = str_count(typeAction, " ") + 1) %>%
  filter(n_shots > 1000)

ggplot(data = shot_desc, aes(x = n_words, y = perc_made)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  ggtitle("Shot label issue") +
  xlab("Number of words used to label the shot") +
  ylab("% made") +
  theme_minimal()
  
# Checking R squared

cor(x = shot_desc$n_words, y = shot_desc$perc_made)

# The correlation is not too strong but it is positive, as we expected

# Shot distribution per quarter

zoneBasicPerQuarter <-  nba_shots %>%
  filter(numberPeriod <= 4) %>%
  group_by(numberPeriod, zoneBasic) %>%
  summarise(n_shots = n())

zoneBasicPerQuarterPerc <- nba_shots %>%
  group_by(numberPeriod) %>%
  summarise(total_shots_quarter = n()) %>%
  right_join(zoneBasicPerQuarter) %>%
  mutate(perc_total = round(n_shots / total_shots_quarter * 100 , 2))

# No free scales

ggplot(data = zoneBasicPerQuarterPerc, aes(x = numberPeriod, y = perc_total)) +
  geom_line() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(vars(zoneBasic)) +
  xlab("Quarter") +
  ylab("Percentage of all shots") +
  ggtitle("Distribution of shots per quarter") +
  theme_minimal()
  
# Free y scale

ggplot(data = zoneBasicPerQuarterPerc, aes(x = numberPeriod, y = perc_total)) +
  geom_line() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(vars(zoneBasic), scales = "free_y") +
  xlab("Quarter") +
  ylab("Percentage of all shots") +
  ggtitle("Distribution of shots per quarter") +
  theme_minimal()
  
# Average distance of shot per minute

nba_shots_rem <- nba_shots %>%
  filter(numberPeriod <= 4) %>%
  mutate(timeElapsed = (numberPeriod * 12) - minutesRemaining) %>%
  group_by(timeElapsed) %>%
  summarise(avg_distance = mean(distanceShot)) %>%
  filter(timeElapsed >= 1)

# There are only three shots with 0 minutes elapsed, so it is better to filter
# them out with such a small sample:

cero_minutes_elapsed <- nba_shots %>%
  filter(numberPeriod <= 4) %>%
  mutate(timeElapsed = (numberPeriod * 12) - minutesRemaining) %>%
  group_by(timeElapsed) %>%
  summarise(n_shots = n()) %>%
  filter(timeElapsed == 0)

cero_minutes_elapsed

ggplot(data = nba_shots_rem, aes(x = timeElapsed, y = avg_distance)) +
  geom_line() +
  geom_smooth(method = "lm", se = FALSE) +
  scale_x_discrete(limits = c(0, 12, 24, 36, 48)) +
  xlab("Time elapsed") +
  ylab("Average distance of shots (feet)") +
  ggtitle("How does the average distance of shots change as the game goes on?") +
  theme_minimal()

# Shooting zones evolution. Filtering out backcourt shots and NA position groups

shooting_zones <- nba_shots %>%
  group_by(yearSeason, zoneBasic, groupPosition) %>%
  summarise(n_shots = n(), perc_made = sum(isShotMade) / n()) %>%
  filter(zoneBasic != "Backcourt" & groupPosition != "NA")

# Frequency of attempts

ggplot(data = shooting_zones, aes(x = yearSeason, y = n_shots, colour = groupPosition)) +
  geom_line() +
  geom_smooth(method = "lm", se = FALSE) +
  facet_wrap(vars(zoneBasic), scales = "free_y") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
  xlab("Year") +
  ylab("Number of shots") +
  ggtitle("Number of shots per zone and position") +
  theme_minimal()

# Accuracy

ggplot(data = shooting_zones, aes(x = yearSeason, y = perc_made, colour = groupPosition)) +
  geom_line() +
  geom_smooth(se = FALSE, method = "lm") +
  facet_wrap(vars(zoneBasic), scales = "free_y") +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
  labs(x = "Year",
       y = "% of made shots",
       title = "Evolution of shot accuracy",
       colour = "Group position") +
  theme_minimal()

# Average distance of non-corner threes taken per position

nba_shots %>%
  filter(!is.na(groupPosition) & zoneBasic == "Above the Break 3") %>%
  group_by(yearSeason, groupPosition) %>%
  summarise(avg_distance = mean(distanceShot)) %>%
  ggplot(aes(x = yearSeason, y = avg_distance)) +
  geom_line() +
  geom_smooth(se = FALSE, method = "lm") +
  facet_wrap(vars(groupPosition)) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
  labs(x = "Year",
       y = "Average distance of 3-point shot (feet)",
       title = "Evolution of the average distance for above the break 3s") +
  theme_minimal()

# Average distance of above the break threes taken by team

nba_shots %>%
  filter(zoneBasic == "Above the Break 3") %>%
  group_by(yearSeason, nameTeam) %>%
  summarise(avg_3_distance = mean(distanceShot)) %>%
  ggplot(aes(x = yearSeason, y = avg_3_distance)) +
  geom_line() +
  geom_smooth(se = FALSE, method = "lm") +
  facet_wrap(vars(nameTeam)) +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1)) +
  labs(x = "Year",
       y = "Average distance of 3-points shots (feet)",
       title = "Evolution of 3-points shots distance") +
  theme_minimal()

# Proportion of corner 3s to above the break 3s for teams

prop_corner <- nba_shots %>%
  mutate(zoneBasic = case_when(
    zoneBasic == "Left Corner 3" ~ "Corner 3",
    zoneBasic == "Right Corner 3" ~ "Corner 3",
    TRUE ~ zoneBasic
  )) %>%
  filter(zoneBasic %in% c("Corner 3", "Above the Break 3")) %>%
  group_by(nameTeam, yearSeason) %>%
  summarise(prop_corner_3s = sum(zoneBasic == "Corner 3") / n())
  
  
ggplot(data = prop_corner, aes(x = yearSeason, y = prop_corner_3s)) +
  geom_line() +
  geom_smooth(se = FALSE, method = "lm") +
  facet_wrap(vars(nameTeam)) +
  labs(x = "Year",
       y = "Proportion of threes taken from the corners",) +
  theme_minimal()

# The same but for positions

prop_corner_position <- nba_shots %>%
  filter(!is.na(groupPosition)) %>%
  mutate(zoneBasic = case_when(
    zoneBasic == "Left Corner 3" ~ "Corner 3",
    zoneBasic == "Right Corner 3" ~ "Corner 3",
    TRUE ~ zoneBasic
  )) %>%
  filter(zoneBasic %in% c("Corner 3", "Above the Break 3")) %>%
  group_by(groupPosition, yearSeason) %>%
  summarise(prop_corner_3s = sum(zoneBasic == "Corner 3") / n())

ggplot(data = prop_corner_position, aes(x = yearSeason, y = prop_corner_3s, 
                                        color = groupPosition)) +
  geom_line() +
  geom_smooth(se = FALSE, method = "lm") +
  labs(x = "Year",
       y = "Proportion of threes taken from the corners",
       color = "Group position") +
  theme_minimal()

