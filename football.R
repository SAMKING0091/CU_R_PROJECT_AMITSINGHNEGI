# =============================================
# FOOTBALL MATCH + PLAYER ANALYSIS 
# =============================================

# ---- Libraries ----
library(tidyverse)
library(ggplot2)
library(reshape2)
library(fmsb)
library(ggcorrplot)
library(gridExtra)

# ---- Step 1: Create In-Memory Data ----
match_data <- data.frame(
  Team = c("Team A", "Team B"),
  Possession = c(62, 38),
  Shots = c(18, 9),
  ShotsOnTarget = c(6, 5),
  PassAccuracy = c(88, 76),
  Fouls = c(10, 14),
  Corners = c(9, 3),
  Goals = c(2, 1),
  xG = c(2.1, 1.6)
)

player_data <- data.frame(
  Player = c("John Smith", "David Lee", "Carlos Mendes",
             "James O’Neill", "Ali Khan", "Luis Garcia"),
  Team = c("Team A", "Team A", "Team A", "Team B", "Team B", "Team B"),
  Minutes = c(90, 88, 90, 90, 85, 90),
  Passes = c(75, 60, 40, 55, 45, 30),
  PassAccuracy = c(92, 87, 80, 78, 75, 70),
  Shots = c(3, 2, 1, 4, 2, 1),
  Goals = c(1, 0, 1, 1, 0, 0),
  Assists = c(1, 1, 0, 0, 0, 0),
  Tackles = c(2, 3, 1, 2, 4, 5),
  DuelsWon = c(5, 4, 2, 3, 4, 2)
)

cat("===== TEAM SUMMARY =====\n")
print(match_data)
cat("===== PLAYER DATA =====\n")
print(player_data)

# ---- Step 2: Team Comparison ----
metrics <- match_data %>%
  select(Team, Possession, Shots, ShotsOnTarget, PassAccuracy, Goals) %>%
  pivot_longer(cols = -Team, names_to = "Metric", values_to = "Value")

p1 <- ggplot(metrics, aes(x = Metric, y = Value, fill = Team)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = " Team Match Statistics Comparison") +
  theme_minimal()

# ---- Step 3: Goal Contributors ----
p2 <- ggplot(player_data, aes(x = reorder(Player, Goals), y = Goals, fill = Team)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = "Top Goal Contributors", x = "Player", y = "Goals") +
  theme_minimal()

# ---- Step 4: Pass Accuracy ----
p3 <- ggplot(player_data, aes(x = Player, y = PassAccuracy, fill = Team)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(title = " Player Pass Accuracy", x = "Player", y = "% Accuracy") +
  theme_minimal()

# ---- Step 5: Possession Pie ----
p4 <- ggplot(match_data, aes(x = "", y = Possession, fill = Team)) +
  geom_bar(stat = "identity", width = 1) +
  coord_polar("y") +
  labs(title = " Team Possession Share") +
  theme_void()

# ---- Step 6: Team Performance Line ----
line_data <- match_data %>%
  select(Team, Shots, ShotsOnTarget, Goals, xG) %>%
  pivot_longer(cols = -Team, names_to = "Metric", values_to = "Value")

p5 <- ggplot(line_data, aes(x = Metric, y = Value, group = Team, color = Team)) +
  geom_line(size = 1.2) + geom_point(size = 3) +
  labs(title = " Team Performance Line Graph") +
  theme_minimal()

# ---- Step 7: Goals vs Pass Accuracy Scatter ----
p6 <- ggplot(player_data, aes(x = PassAccuracy, y = Goals, color = Team)) +
  geom_point(size = 4) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
  labs(title = "Goals vs Pass Accuracy", x = "Pass Accuracy (%)", y = "Goals") +
  theme_minimal()

# ---- Step 8: Defensive Actions ----
defense_data <- player_data %>%
  group_by(Team) %>%
  summarise(Total_Tackles = sum(Tackles), Total_Duels = sum(DuelsWon)) %>%
  pivot_longer(cols = -Team, names_to = "Action", values_to = "Count")

p7 <- ggplot(defense_data, aes(x = Action, y = Count, fill = Team)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = " Defensive Actions by Team", x = "Action Type", y = "Count") +
  theme_minimal()

# ---- Step 9: Heatmap ----
heatmap_data <- player_data %>%
  select(Player, PassAccuracy, Shots, Goals, Assists, Tackles, DuelsWon) %>%
  column_to_rownames("Player")
heatmap_matrix <- as.matrix(heatmap_data)
heatmap(scale(heatmap_matrix),
        Colv = NA, Rowv = NA,
        col = colorRampPalette(c("red", "white", "green"))(100),
        main = " Player Performance Heatmap")

# ---- Step 10: Radar Chart ----
player1 <- player_data[player_data$Player == "John Smith", ]
player2 <- player_data[player_data$Player == "James O’Neill", ]

radar_stats <- data.frame(
  Metric = c("PassAccuracy", "Shots", "Goals", "Assists", "Tackles", "DuelsWon"),
  John_Smith = unlist(player1[1, c("PassAccuracy", "Shots", "Goals", "Assists", "Tackles", "DuelsWon")]),
  James_ONeill = unlist(player2[1, c("PassAccuracy", "Shots", "Goals", "Assists", "Tackles", "DuelsWon")])
)

radar_scaled <- as.data.frame(rbind(
  rep(100, nrow(radar_stats)),   # max
  rep(0, nrow(radar_stats)),     # min
  radar_stats$John_Smith,
  radar_stats$James_ONeill
))
colnames(radar_scaled) <- radar_stats$Metric
rownames(radar_scaled) <- c("Max", "Min", "John Smith", "James O’Neill")

colors <- c(rgb(0.2, 0.6, 0.9, 0.5), rgb(0.9, 0.3, 0.3, 0.5))
radarchart(radar_scaled,
           axistype = 1,
           pcol = c("blue", "red"),
           pfcol = colors,
           plwd = 2,
           title = " Player Performance Radar Chart")
legend("bottomright", legend = c("John Smith", "James O’Neill"), col = c("blue", "red"), lty = 1, lwd = 3, bty = "n")

# ---- Step 11: Correlation Plot ----
corr_matrix <- cor(player_data %>% select(PassAccuracy, Shots, Goals, Assists, Tackles, DuelsWon))
ggcorrplot(corr_matrix, method = "circle", lab = TRUE, title = "📈 Correlation Between Player Metrics")

# ---- Step 12: Display All Plots Together ----
grid.arrange(p1, p4, p5, p6, p7, ncol = 2)

# ---- Step 13: Summary ----
cat("\n===== PLAYER PERFORMANCE SUMMARY =====\n")
top_scorer <- player_data$Player[which.max(player_data$Goals)]
top_passer <- player_data$Player[which.max(player_data$PassAccuracy)]
top_defender <- player_data$Player[which.max(player_data$Tackles)]
cat("Top Scorer:", top_scorer, "\n")
cat("Best Pass Accuracy:", top_passer, "\n")
cat("Most Tackles:", top_defender, "\n")

cat("\n===== MATCH TAKEAWAYS =====\n")
cat("Team", match_data$Team[which.max(match_data$Goals)], "won the match.\n")
