# Setup ####
list.of.packages <- c("data.table", "rstudioapi", "scales")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) 
setwd(wd)
setwd("../")

# Data to emulate
model = fread("https://raw.githubusercontent.com/devinit/gha-data-visualisations/2fd6563d79c5849292c7c29deadbac8e6d142897/public/assets/data/climate-finance-bubble-data.csv")

# Extract bubble regions
# bubble_regions = unique(model[,c("ISO3","Region")])
# bubble_regions$Region[which(bubble_regions$ISO3=="XKX")] = "Europe"
# missing_regions = data.table(
#   ISO3=c(
#     "CHL", "COK", "SYC", "URY"
#   ),
#   Region=c(
#     "Latin America and the Caribbean", "Asia", "Africa", "Latin America and the Caribbean"
#   )
# )
# bubble_regions = rbind(bubble_regions, missing_regions)
# fwrite(bubble_regions, "input/bubble_regions.csv")
bubble_regions = fread("input/bubble_regions.csv")
setnames(bubble_regions, "ISO3", "iso3")

# Load data
dat = fread("input/climate-finance-bubble-intermediate.csv")
dat = subset(dat, year==2022)
# Remove unused cols
dat[,c(
  "year",
  "region",
  "CCM_Share",
  "Dual_Share",
  "Vulnerability_Score",
  "protracted_crisis"
)] = NULL

# Merge bubble regions
dat = merge(dat, bubble_regions, by="iso3", all.x=T)

# Load pop
# source("~/git/gha_report_2023/datasets/Population/wupData.R")
# pop = wup_get()
# fwrite(pop,"input/population.csv")
pop = fread("input/population.csv")
pop = subset(pop, area=="total" & year==2022)
pop[,c("area", "year")] = NULL
setnames(pop, c("ISO3", "population"), c("iso3", "Population"))
dat = merge(dat, pop, by="iso3", all.x=T)

# Calculate new shares
dat$`Adaptation Share` = dat$CCA_USD / dat$Total_Climate_USD
dat$`Mitigation Share` = dat$CCM_USD / dat$Total_Climate_USD
dat$`Dual Purpose Share` = dat$Dual_Purpose_USD / dat$Total_Climate_USD
dat$`Funding per capita (US$)` = (dat$Total_Climate_USD * 1e6) / dat$Population

# Load crises classes
pccs = fread("~/git/gha_report_2023/chapter_4/f_4.3_cca_ccm/Protracted Crisis/protracted_crisis_classifications.csv")
pccs = subset(pccs, year==2022)
pccs$`Crisis Class` = ""
pccs$`Crisis Class`[which(pccs$crisis_class=="PC")] = "Protracted Crisis"
pccs$`Crisis Class`[which(pccs$crisis_class %in% c("RC", "C"))] = "Crisis"
pccs = pccs[,c("iso3", "Crisis Class")]
dat = merge(dat, pccs, by="iso3", all.x=T)

# Load food insecurity gaps
gaps = fread("~/git/gha_report_2023/datasets/IPC/all_food_insecurity_gaps.csv")
gaps = subset(gaps, year==2022)
gaps = gaps[,c("iso3","fi_1")]
setnames(gaps,"fi_1", "Food Insecurity Gap")
dat = merge(dat, gaps, by="iso3", all.x=T)

# Rename
setnames(
  dat,
  c(
    "countryname",
    "iso3",
    "CCA_USD",
    "CCM_USD",
    "Dual_Purpose_USD",
    "Total_Climate_USD",
    "Vulnerability_Score_new",
    "Total_ODA_USD",
    "Total_Climate_Share",
    "CCA_Share"
    ),
  c(
    "Country",
    "ISO3",
    "Adaptation",
    "Mitigation",
    "Dual Purpose",
    "Total Funding",
    "Vulnerability",
    "ODA",
    "Funding share of ODA",
    "Adaptation Share ODA(%)"
    )
)

model_names = c(
  "Country",
  "ISO3",
  "Adaptation",
  "Mitigation",
  "Dual Purpose",
  "Adaptation Share",
  "Mitigation Share",
  "Dual Purpose Share",
  "Total Funding",
  "Vulnerability",
  "Region",
  "ODA",
  "Funding share of ODA",
  "Food Insecurity Gap",
  "Crisis Class",
  "Population",
  "Funding per capita (US$)",
  "Adaptation Share ODA(%)"
)

setdiff(names(dat), model_names)
setdiff(model_names, names(dat))

dat = dat[,model_names,with=F]
# Format
dat$Adaptation = round(dat$Adaptation, 2)
dat$Mitigation = round(dat$Mitigation, 2)
dat$`Dual Purpose` = round(dat$`Dual Purpose`, 2)
dat$`Adaptation Share`[which(is.nan(dat$`Adaptation Share`))] = NA
dat$`Adaptation Share` = label_percent(accuracy=1)(dat$`Adaptation Share`)
dat$`Mitigation Share`[which(is.nan(dat$`Mitigation Share`))] = NA
dat$`Mitigation Share` = label_percent(accuracy=1)(dat$`Mitigation Share`)
dat$`Dual Purpose Share`[which(is.nan(dat$`Dual Purpose Share`))] = NA
dat$`Dual Purpose Share` = label_percent(accuracy=1)(dat$`Dual Purpose Share`)
dat$`Total Funding` = round(dat$`Dual Purpose`, 2)
dat$`Vulnerability` = round(dat$`Vulnerability` / 100, 4)
dat$`Funding share of ODA`[which(is.na(dat$`Funding share of ODA`))] = 0
dat$`Funding share of ODA` = label_percent(accuracy=0.01)(dat$`Funding share of ODA`)
dat$`Food Insecurity Gap` = label_percent(accuracy=1)(dat$`Food Insecurity Gap`)
dat$`Adaptation Share ODA(%)`[which(is.na(dat$`Adaptation Share ODA(%)`))] = 0
dat$`Adaptation Share ODA(%)` = dat$`Adaptation Share ODA(%)` * 100

# Write
fwrite(dat, "output/climate-finance-bubble-data.csv")
