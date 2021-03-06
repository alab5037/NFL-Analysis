# New Orleans Saints Offensive Analysis
## By Hajime Alabanza

## Part I: Data Collection/Assembly ##

# First, I import files into R. These files are available on Kaggle: https://www.kaggle.com/maxhorowitz/nflplaybyplay2009to2016

# load tidyverse package
library('tidyverse')

# import dataframes
pbp_2019 = read_csv("/Users/halabanz/Desktop/case study/NFL/reg_pbp_2019.csv")
outcome_2019 = read_csv("/Users/halabanz/Desktop/case study/NFL/reg_games_2019.csv")


## Part II: Preprocessing ##

# In this section, I do some basic preprocessing such as creating a column for the winning team, which will be used in the analysis.

# include winning posteam 
outcome_2019 = outcome_2019 %>% select(c(2,9,10))
pbp_2019 = inner_join(pbp_2019, outcome_2019, by = "game_id")
pbp_2019 = pbp_2019 %>% mutate(win = ifelse((posteam == home_team & home_score > away_score) | (posteam == away_team & away_score > home_score), 1, 0))

# add years column to dataframe
pbp_2019 = pbp_2019 %>% mutate(year = format(as.Date(game_date, format="%Y-%m-%d"),"%Y"))


## Part III: Exploratory Analysis ##

# In this section, I analyze the Saint's offense for the 2019 season. I provide some general statistics on overall offensive performance 

# Points scored
pbp_2019 %>% filter(posteam == 'NO') %>% group_by(defteam, game_date) %>% summarise(points_scored = max(posteam_score, na.rm = T), won = ifelse(sum(win) > 1, 1,0)) %>% ggplot(aes(x = game_date, y = points_scored, label = defteam)) + geom_line(linetype = 2) + ggtitle("Points Scored") + xlab('') + ylab('Points') + geom_label(aes(fill = factor(won)), colour = "white", fontface = "bold") + scale_fill_manual(name = 'Outcome', values = c("red", "green"),labels = c("Lost", "Won")) + theme_bw() + theme(text=element_text(size=12,  family="Comic Sans MS"))

# Percent of scoring drives: td vs. field goal
pbp_2019 %>% filter(posteam == 'NO') %>% group_by(defteam, game_date) %>% summarise(drives = length(unique(drive)), td = ((sum(play_type == 'extra_point') + sum(!is.na(two_point_conv_result)))/drives)*100, field_goal = (sum(play_type == 'field_goal')/drives)*100) %>% gather(key = "result", value = "proportion", td, field_goal) %>% arrange(game_date) %>% ggplot(aes(x = game_date, y = proportion, color = result)) + geom_smooth(method = 'loess', se = F) + ggtitle("Percent of Drives Resulting in TD vs. FG") + xlab('') + ylab('%') + theme_bw() + theme(text=element_text(size=12,  family="Comic Sans MS"))

# Drives: Run vs. Pass (Entire Season)
pbp_2019 %>% filter((play_type == 'run' | play_type == 'pass' ) & posteam == 'NO' & is.na(two_point_conv_result)) %>% summarise(run = round((sum(play_type == 'run')/n())*100,1), pass = round((sum(play_type == 'pass')/n())*100,1)) %>% gather("play_type", "proportion", run, pass) %>% ggplot(aes(x = play_type, y = proportion)) + geom_col(fill = "tomato1") + ggtitle('Run vs. Pass') + theme_bw() + theme(text=element_text(size=12,  family="Comic Sans MS")) + ylab("%")

# Average pass WPA rankings in 2019 
pbp_2019 %>% filter(play_type == "pass" | (play_type == "no_play" & interception == 1) | (play_type == "no_play" & incomplete_pass == 1) | (play_type == "no_play" & str_detect(desc, "Grounding"))) %>% group_by(posteam) %>% summarise(avg_wpa = round(mean(wpa, na.rm = T), 4)*100, attempts = n()) %>% arrange(desc(avg_wpa)) %>% ggplot(aes(x = reorder(posteam, avg_wpa), y = avg_wpa, fill = attempts)) + geom_col() + coord_flip() + labs(title = "2019 Pass Rankings") + xlab("Team") + theme(legend.position = "none") + ylab("Avg. WPA per Pass (%)") + theme_bw() + theme(text=element_text(size=12, family="Comic Sans MS")) + scale_fill_gradient(low = "tomato1", high = "green", name = "Pass Attempts")

# Pass attempt proportion and avg wpa for qbs (short: up to 15 air yards)
pbp_2019 %>% filter(play_type == "pass" | (play_type == "no_play" & interception == 1) | (play_type == "no_play" & incomplete_pass == 1) | (play_type == "no_play" & str_detect(desc, "Grounding"))) %>% mutate(passer_player_name = ifelse(passer_player_name == "D.Brees" | passer_player_name == "T.Bridgewater", passer_player_name, "League Average")) %>% group_by(passer_player_name, pass_length) %>% summarise(total_wpa = sum(wpa, na.rm = T), avg_wpa = round(mean(wpa, na.rm = T),3)*100, attempts = n()) %>% group_by(passer_player_name) %>% filter(!is.na(pass_length)) %>% mutate(pass_proportion = (attempts/sum(attempts))*100) %>% arrange(desc(avg_wpa)) %>% filter(attempts >= 5) %>% ggplot(aes(x = pass_length, y = passer_player_name, color = avg_wpa, size = pass_proportion)) + geom_point() + scale_color_gradient(low = "tomato1", high = "green") + xlab("Distance") + ylab("") + labs(color = "Avg. WPA per Pass (%)") + labs(size = "Proportion of Passes (%)") + labs(title = "Pass by Distance", subtitle = "Min. 10 Pass Attempts") + theme_bw() + theme(text=element_text(size=11, family="Comic Sans MS"))

# Median deep targets
median_deep_targets = pbp_2019 %>% filter((play_type == "pass" & pass_length == "deep")) %>% group_by( receiver_player_name) %>% summarise(attempts = n()) %>% filter(!is.na(receiver_player_name)) %>% summarise(med_deep_target = median(attempts, na.rm = T))

# Targets proportion and avg wpa for wrs (Median deep threat targets per season is 5)
pbp_2019 %>% filter(play_type == "pass" | (play_type == "no_play" & interception == 1) | (play_type == "no_play" & incomplete_pass == 1)) %>% mutate(receiver_player_name = ifelse((receiver_player_id == "00-0034765" & receiver_player_name == "T.Smith") | (receiver_player_id == "00-0032765" & receiver_player_name == "M.Thomas") | (receiver_player_id == "00-0033357" & receiver_player_name == "T.Hill") | (receiver_player_id == "00-0027061" & receiver_player_name == "J.Cook") | (receiver_player_id == "00-0025396" & receiver_player_name == "T.Ginn") | (receiver_player_id == "00-0033906" & receiver_player_name == "A.Kamara") | (receiver_player_id == "00-0030216" & receiver_player_name == "J.Hill") | (receiver_player_id == "00-0030513" & receiver_player_name == "L.Murray") | (receiver_player_id == "00-0029931" & receiver_player_name == "Z.Line"), receiver_player_name, "League Average")) %>% group_by(receiver_player_name, pass_length) %>% summarise(total_wpa = sum(wpa, na.rm = T), avg_wpa = round(mean(wpa, na.rm = T),3)*100, attempts = n()) %>% filter(!is.na(pass_length) & !is.na(receiver_player_name)) %>% group_by(receiver_player_name) %>% mutate(pass_proportion = (attempts/sum(attempts))*100) %>% arrange(desc(avg_wpa)) %>% filter(attempts >= 5) %>% ggplot(aes(x = pass_length, y = receiver_player_name, color = avg_wpa, size = pass_proportion)) + geom_point() + scale_color_gradient(low = "tomato1", high = "green") + xlab("Distance") + ylab("") + labs(color = "Avg. WPA per Target (%)") + labs(title = "Receiving by Distance", subtitle = "Min. 5 Targets", size = "Proportion of Targets (%)") + theme_bw() + theme(text=element_text(size=12,  family="Comic Sans MS")) + guides(color = guide_colourbar(order=1), size = guide_legend(order=2))

# The number of deep targeted receivers (> 5) per team
pbp_2019 %>% filter((play_type == "pass" & pass_length == "deep")| (play_type == "no_play" & interception == 1 & pass_length == "deep") | (play_type == "no_play" & incomplete_pass == 1 & pass_length == "deep")) %>% group_by(posteam, receiver_player_name) %>% summarise(attempts = n()) %>% filter(!is.na(receiver_player_name)) %>% mutate(ge_10_targets = ifelse(attempts >= 5, 1, 0)) %>% group_by(posteam) %>% summarise(number_deep_threats = sum(ge_10_targets, na.rm = T)) %>% arrange(desc(number_deep_threats)) %>% ggplot(aes(x = reorder(posteam, number_deep_threats), y = number_deep_threats)) + geom_col(fill = "tomato1") + coord_flip() + theme_bw() + theme(text=element_text(size=12,  family="Comic Sans MS")) + theme(legend.position = "none") + xlab("Team") + ylab("No. of Pass Catchers") + labs(title = "Deep Pass Options per Team", subtitle = "Min. 5 Targets")

# Avg wpa: deep vs. short
pbp_2019 %>% filter(play_type == "pass" | (play_type == "no_play" & interception == 1) | (play_type == "no_play" & incomplete_pass == 1)) %>% group_by(pass_length) %>% summarise(avg_wpa = round(mean(wpa, na.rm = T), 4)*100, attempts = n()) %>% arrange(desc(avg_wpa)) %>% filter(!is.na(pass_length)) %>% ggplot(aes(x = reorder(pass_length, avg_wpa), y = avg_wpa)) + geom_col(fill = "tomato1") + coord_flip() + ylab("Avg. WPA per Pass (%)") + labs(title = "WPA Based on Pass Distance") + theme_bw() + theme(text=element_text(size=12, family="Comic Sans MS")) + xlab("Distance")

# Lets look at top deep threat receivers in the league 
top_deep_threats = pbp_2019 %>% filter((play_type == "pass" & pass_length == "deep") | (play_type == "no_play" & interception == 1 & pass_length == "deep") | (play_type == "no_play" & incomplete_pass == 1 & pass_length == "deep")) %>% group_by(receiver_player_name, pass_length) %>% summarise(total_wpa = sum(wpa, na.rm = T), avg_wpa = round(mean(wpa, na.rm = T),3)*100, attempts = n()) %>% group_by(receiver_player_name) %>% arrange(desc(avg_wpa)) %>% filter(attempts >= 5)

top_deep_threats$rank = NA
top_deep_threats$rank[1] = 1

for(i in 2:dim(top_deep_threats)[1]) {
  
  if(top_deep_threats$avg_wpa[i - 1] == top_deep_threats$avg_wpa[i]) {
    top_deep_threats$rank[i] = top_deep_threats$rank[i - 1]
  } 
  else{
    top_deep_threats$rank[i] = top_deep_threats$rank[i - 1] + 1
  }
}

# top deep threat free agents 
top_deep_threats %>% filter(receiver_player_name == "E.Sanders" | receiver_player_name == "R.Cobb" | receiver_player_name == "Ro.Anderson" | receiver_player_name == "N.Agholor" | receiver_player_name == "A.Hooper" | receiver_player_name == "B.Perriman" | receiver_player_name == "D.Robinson" | receiver_player_name == "J.Graham" | receiver_player_name == "A.Cooper" | receiver_player_name == "P.Dorsett") %>% ggplot(aes(x = reorder(receiver_player_name, avg_wpa), y = avg_wpa)) + geom_col(fill = "tomato1") + coord_flip() + labs(title = "2020 Free Agents", subtitle = "Min. 5 Targets") + theme_bw() + theme(text=element_text(size=12,  family="Comic Sans MS")) + xlab("Player") + ylab("Avg. WPA per Deep Target (%)") + scale_fill_gradient(low = "tomato1", high = "green", name = "No. of Targets")
