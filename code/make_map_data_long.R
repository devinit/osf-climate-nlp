# Setup ####
list.of.packages <- c("data.table", "rstudioapi", "scales")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) 
setwd(wd)
setwd("../")

# Load long dataset we're trying to recreate
# long_model = fread("https://raw.githubusercontent.com/devinit/gha-data-visualisations/6104e0e9262dd703a9c3cb6f9a7cfd141f2a5724/public/assets/data/climate_funding_data_long_format.csv")
# Extract metadata on regions
# regions = unique(long_model[,c("iso3", "region")])
# fwrite(regions,"input/regions.csv")
regions = fread("input/regions.csv")

# Load source dataset and subset to ODA
dat = fread("~/git/gha_report_2023/chapter_4/f_4.3_cca_ccm/f3_cca_ccm_analysis.csv")
dat = subset(dat, FlowName!="Private Development Finance")

# Make PCs metadata
dat$protracted_crisis = ""
dat$protracted_crisis[which(dat$crisis_class=="PC")] = "yes"

pcs = unique(dat[,c("RecipientISO", "Year", "protracted_crisis")])
setnames(pcs, c("RecipientISO", "Year"), c("iso3", "year"))

# Make vuln metadata
dat$Vulnerability_Score_new = 100 - dat$gain
vuln = unique(dat[,c("RecipientISO", "Year", "Vulnerability_Score_new")])
setnames(vuln, c("RecipientISO", "Year"), c("iso3", "year"))

# Make financial sums
cca = subset(dat, Primary_CCA=="CCA" & Primary_CCM!="CCM")
ccm = subset(dat, Primary_CCA!="CCA" & Primary_CCM=="CCM")
dual = subset(dat, Primary_CCA=="CCA" & Primary_CCM=="CCM")
total_clim = subset(dat, Primary_CCA=="CCA" | Primary_CCM=="CCM")

cca_sum = cca[,.(CCA_USD=sum(USD_Disbursement_Defl, na.rm=T)),by=.(
  RecipientISO, RecipientName, Year
)]
ccm_sum = ccm[,.(CCM_USD=sum(USD_Disbursement_Defl, na.rm=T)),by=.(
  RecipientISO, RecipientName, Year
)]
dual_sum = dual[,.(Dual_Purpose_USD=sum(USD_Disbursement_Defl, na.rm=T)),by=.(
  RecipientISO, RecipientName, Year
)]
total_clim_sum = total_clim[,.(Total_Climate_USD=sum(USD_Disbursement_Defl, na.rm=T)),by=.(
  RecipientISO, RecipientName, Year
)]
total_oda_sum = dat[,.(Total_ODA_USD=sum(USD_Disbursement_Defl, na.rm=T)),by=.(
  RecipientISO, RecipientName, Year
)]

# Merge all datasets
dat_merge = merge(
  cca_sum,
  ccm_sum,
  all=T
)

dat_merge = merge(
  dat_merge,
  dual_sum,
  all=T
)

dat_merge = merge(
  dat_merge,
  total_clim_sum,
  all=T
)

dat_merge = merge(
  dat_merge,
  total_oda_sum,
  all=T
)

setnames(
  dat_merge,
  c("RecipientISO", "RecipientName", "Year"),
  c("iso3", "countryname", "year")
)

dat_merge = merge(
  dat_merge,
  regions,
  by="iso3",
  all.x=T
)

dat_merge = merge(
  dat_merge,
  pcs,
  by=c("iso3", "year"),
  all.x=T
)

dat_merge = merge(
  dat_merge,
  vuln,
  by=c("iso3", "year"),
  all.x=T
)

dat_merge = subset(dat_merge, iso3!="")

# Expand into all possible combinations of year and iso3
dat_grid = expand.grid(
  iso3=unique(dat_merge$iso3),
  year=unique(dat_merge$year)
)

dat_merge = merge(
  dat_merge,
  dat_grid,
  by=c("iso3", "year"),
  all=T
)

# Fill blanks with 0 where applicable
dat_merge$CCA_USD[which(is.na(dat_merge$CCA_USD))] = 0
dat_merge$CCM_USD[which(is.na(dat_merge$CCM_USD))] = 0
dat_merge$Dual_Purpose_USD[which(is.na(dat_merge$Dual_Purpose_USD))] = 0
dat_merge$Total_Climate_USD[which(is.na(dat_merge$Total_Climate_USD))] = 0
dat_merge$Total_ODA_USD[which(is.na(dat_merge$Total_ODA_USD))] = 0

# Create shares and dup var
dat_merge$CCA_Share = dat_merge$CCA_USD / dat_merge$Total_ODA_USD
dat_merge$CCM_Share = dat_merge$CCM_USD / dat_merge$Total_ODA_USD
dat_merge$Dual_Share = dat_merge$Dual_Purpose_USD / dat_merge$Total_ODA_USD
dat_merge$Total_Climate_Share = dat_merge$Total_Climate_USD / dat_merge$Total_ODA_USD
dat_merge$Vulnerability_Score = dat_merge$Vulnerability_Score_new

# Melt long
dat_long = melt(
  dat_merge,
  id.vars=c("countryname","iso3","year","region","protracted_crisis"),
  value.name="value_precise"
)

# Merge units
# units = unique(long_model[,c("variable", "unit")])
# fwrite(units, "input/units.csv")
units = fread("input/units.csv")

setdiff(unique(units$variable), unique(dat_long$variable))
setdiff(unique(dat_long$variable), unique(units$variable))

dat_long = merge(
  dat_long,
  units,
  by="variable",
  all.x=T
)

# Format depending on unit
dat_long$value_precise[which(is.nan(dat_long$value_precise))] = 0
dat_long$value_precise[
  which(dat_long$unit=="percentage_share")
] = round(dat_long$value_precise[
  which(dat_long$unit=="percentage_share")
] * 100, 2)
dat_long$value_fixed = dat_long$value_precise
dat_long$value_precise[
  which(dat_long$unit=="percentage_share")
] = paste0(
  dat_long$value_precise[
    which(dat_long$unit=="percentage_share")
  ], "%"
)

dat_long$value_fixed[
  which(dat_long$unit=="usd_millions")
] = round(
  dat_long$value_fixed[
    which(dat_long$unit=="usd_millions")
  ], 2
)

dat_long$value_fixed[
  which(dat_long$unit=="index")
] = round(
  dat_long$value_fixed[
    which(dat_long$unit=="index")
  ], 2
)

long_model_names = c(
  "countryname",
  "iso3",
  "year",
  "region",
  "protracted_crisis",
  "variable",
  "unit",
  "value_precise",
  "value_fixed"
)

setdiff(names(dat_long), long_model_names)
setdiff(long_model_names, names(dat_long))

dat_long = dat_long[,long_model_names,with=F]
fwrite(dat_long, "output/climate_funding_data_long_format.csv")
