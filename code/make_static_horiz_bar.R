list.of.packages <- c("data.table", "ggplot2", "dplyr", "rstudioapi")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) 
setwd(wd)
setwd("../")

data = fread("output/climate-finance-bubble-data.csv")
data = subset(data, `Crisis Class`=="Protracted Crisis")
data$m_share = as.numeric(gsub("%", "", data$`Mitigation Share`))
data = data[order(-data$m_share),]

short_country_names = data$Country
names(short_country_names) = short_country_names
short_country_names[
  which(names(short_country_names)=="Syrian Arab Republic")
] = "Syria"
short_country_names[
  which(names(short_country_names)=="Democratic Republic of the Congo")
] = "DRC"
short_country_names[
  which(names(short_country_names)=="Central African Republic")
] = "CAR"
data$Country = short_country_names[data$Country]

# Countries are categorised into five vulnerability levels: 
# very low (less than 40), low (40–50), 
# medium (50–55), high (55–60), and very high (over 60).
data$v_class = NA
data$v_class[which(data$Vulnerability < 0.4 )] = "Very low vulnerability"
data$v_class[which(data$Vulnerability >= 0.4 )] = "Low vulnerability"
data$v_class[which(data$Vulnerability >= 0.5 )] = "Medium vulnerability"
data$v_class[which(data$Vulnerability >= 0.55 )] = "High vulnerability"
data$v_class[which(data$Vulnerability >= 0.6 )] = "Very high vulnerability"

data = subset(data, !is.na(v_class))
data[,c("Mitigation", "Dual Purpose", "Adaptation")] = NULL

setnames(
  data,
  c("Country", "v_class", "Mitigation Share", "Dual Purpose Share", "Adaptation Share"),
  c("country", "vulnerability", "Mitigation", "Dual purpose", "Adaptation")
)
fwrite(data[,c("country", "Mitigation", "Dual purpose", "Adaptation", "vulnerability")], "output/fig6_data.csv")
data = melt(
  data,
  id.vars=c("country", "vulnerability"),
  measure.vars=c("Mitigation", "Dual purpose", "Adaptation"),
  variable.name="category"
)
data$value = as.numeric(gsub("%", "", data$value, fixed=T))
data = subset(data, !is.na(value))

# Convert 'country' and 'category' into factors to retain order
data$country <- factor(data$country, levels = unique(data$country))
data$category <- factor(data$category, levels = c("Adaptation", "Dual purpose", "Mitigation"))
data$vulnerability = factor(data$vulnerability, levels = rev(c("Very low vulnerability", "Low vulnerability", "Medium vulnerability", "High vulnerability", "Very high vulnerability")))

# Plot
p = ggplot(data, aes(x = country, y = value, fill = category)) +
  geom_bar(stat = "identity", position = "fill") + # Stacked bar chart normalized to 100%
  scale_y_continuous(labels = scales::percent_format(), position="right") + # Display as percentages
  coord_flip() + # Flip coordinates to make horizontal bars
  facet_wrap(~ vulnerability, scales = "free_y", ncol = 1) + # Group by vulnerability
  scale_fill_manual(values = c("Mitigation" = "#e6829e", "Dual purpose" = "#d74079", "Adaptation" = "#7f0f50")) + # Use similar colors
  theme_minimal() +
  labs(
    x = "",
    y = "",
    fill = ""
  ) +
  theme(
    panel.grid.major = element_blank(),
    ,panel.grid.minor = element_blank()
    ,legend.position = "top"
  ) + guides(fill = guide_legend(reverse=T))
p
ggsave(
  "output/Figure_6_Adaptation_and_mitigation_ODA_in_protracted_crisis_countries_2022.png",
  p,
  units="px",
  width=2800,
  height=3200
)
