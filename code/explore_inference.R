# Setup ####
list.of.packages <- c("data.table", "rstudioapi")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) 
setwd(wd)
setwd("../")

mse = function(x, p){return(mean((x-p)^2))}

sigmoid <- function(x) {
  1 / (1 + exp(-x))
}

logit <- function(y) {
  log(y / (1 - y))
}


# Climate change model
dat = fread("output/wb_api_regression_inference.csv")
dat$rail = grepl("\\brail\\b|\\brailway\\b|\\brails\\b|\\brailways\\b", dat$text, ignore.case=T, perl=T)
rail = subset(dat, rail)
nonrail = subset(dat, !rail)
mean(rail$`Climate mitigation`)
mean(nonrail$`Climate mitigation`)
dat$pred = dat$pred + 0.5
dat$`Climate change` = pmin(dat$`Climate change`, 1)
plot(dat$`Climate change`[order(dat$`Climate change`)])
hist(dat$`Climate change`)
plot(density(dat$`Climate change`))

plot(dat$pred[order(dat$pred)])
hist(dat$pred)
plot(density(dat$pred))

dat$pred_cap = pmax(dat$pred, 0)
dat$pred_cap = pmin(dat$pred_cap, 1)
plot(dat$pred_cap[order(dat$pred_cap)])
hist(dat$pred_cap)
plot(density(dat$pred_cap))

par(mfrow=(c(1, 2)))
plot(density(dat$`Climate change`))
plot(density(dat$pred_cap))
dev.off()

mse(dat$`Climate change`, mean(dat$`Climate change`))
mse(dat$`Climate change`, dat$pred_cap)
plot(`Climate change`~pred_cap, data=dat)

summary(lm(`Climate change`~pred_cap, data=dat))

zero_labels = subset(dat, `Climate change` == 0)
boxplot(pred_cap~`Climate change`, data=zero_labels)
nonzero_labels = subset(dat, `Climate change` != 0)
plot(`Climate change`~pred_cap, data=nonzero_labels)
abline(0, 1)
hundred_labels = subset(dat, `Climate change` == 1)
boxplot(pred_cap~`Climate change`, data=hundred_labels)

# Climate adaptation and mitigation model
c_dat = dat
dat = fread("output/wb_dual_regression_inference.csv")

dat$pred_a_cap = pmax(dat$pred_a, 0)
dat$pred_a_cap = pmin(dat$pred_a_cap, 1)

dat$pred_m_cap = pmax(dat$pred_m, 0)
dat$pred_m_cap = pmin(dat$pred_m_cap, 1)

mse(dat$`Climate adaptation`, mean(dat$`Climate adaptation`))
mse(dat$`Climate adaptation`, dat$pred_a)
mse(dat$`Climate adaptation`, dat$pred_a_cap)
plot(`Climate adaptation`~pred_a_cap, data=dat)

summary(lm(`Climate adaptation`~pred_a_cap, data=dat))

mse(dat$`Climate mitigation`, mean(dat$`Climate mitigation`))
mse(dat$`Climate mitigation`, dat$pred_m)
mse(dat$`Climate mitigation`, dat$pred_m_cap)
plot(`Climate mitigation`~pred_m_cap, data=dat)

summary(lm(`Climate mitigation`~pred_m_cap, data=dat))

# Check concurrance between models
dat$pred_sum = dat$pred_a_cap + dat$pred_m_cap
dat$pred_sum = pmax(dat$pred_sum, 0)
dat$pred_sum = pmin(dat$pred_sum, 1)
c_dat = c_dat[,c("id", "pred_cap")]

merge_dat = merge(dat, c_dat, by="id")
plot(pred_cap~pred_sum, data=merge_dat)
summary(lm(pred_cap~pred_sum, data=merge_dat))
mse(merge_dat$pred_cap, merge_dat$pred_sum)
mse(merge_dat$`Climate change`, merge_dat$pred_cap)
mse(merge_dat$`Climate change`, merge_dat$pred_sum)
merge_dat$between_models_error = merge_dat$pred_sum - merge_dat$pred_cap
Hmisc::describe(merge_dat$between_models_error)
merge_dat$between_reality_error = merge_dat$`Climate change` - merge_dat$pred_cap
plot(between_reality_error~between_models_error, data=merge_dat)
summary(lm(between_reality_error~between_models_error, data=merge_dat))
