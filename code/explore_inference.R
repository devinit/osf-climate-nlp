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
dat = fread("output/wb_api_regression_inference_logit.csv")
dat$`Climate change` = pmin(dat$`Climate change`, 1)
plot(dat$`Climate change`[order(dat$`Climate change`)])
hist(dat$`Climate change`)
plot(density(dat$`Climate change`))

dat$sig_pred = sigmoid(dat$pred)

plot(dat$sig_pred[order(dat$sig_pred)])
hist(dat$sig_pred)
plot(density(dat$sig_pred))

par(mfrow=(c(1, 2)))
plot(density(dat$`Climate change`))
plot(density(dat$sig_pred))
dev.off()
# 
# dat$pred_cap = pmax(dat$pred, 0)
# dat$pred_cap = pmin(dat$pred_cap, 1)
# plot(dat$pred_cap[order(dat$pred_cap)])
# hist(dat$pred_cap)

mse(dat$`Climate change`, mean(dat$`Climate change`))
mse(dat$`Climate change`, dat$sig_pred)
# mse(dat$`Climate change`, dat$pred_cap)
plot(`Climate change`~sig_pred, data=dat)

summary(lm(`Climate change`~sig_pred, data=dat))

zero_labels = subset(dat, `Climate change` == 0)
boxplot(sig_pred~`Climate change`, data=zero_labels)
nonzero_labels = subset(dat, `Climate change` != 0)
plot(`Climate change`~sig_pred, data=nonzero_labels)
abline(0, 1)
hundred_labels = subset(dat, `Climate change` == 1)
boxplot(sig_pred~`Climate change`, data=hundred_labels)

dat$binary_cc = (dat$`Climate change` > 0.5) * 1
dat$binary_pred = (dat$sig_pred > 0.5) * 1
# 92% accuracy
mean(dat$binary_cc == dat$binary_pred)

# Climate adaptation and mitigation model
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
