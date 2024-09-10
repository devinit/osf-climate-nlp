# Setup ####
list.of.packages <- c("data.table", "rstudioapi")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) 
setwd(wd)
setwd("../")

mse = function(x, p){return(mean((x-p)^2))}

# Climate change model
dat = fread("output/wb_regression_inference.csv")

dat$pred_cap = pmax(dat$pred, 0)
dat$pred_cap = pmin(dat$pred_cap, 1)

mse(dat$`Climate change`, mean(dat$`Climate change`))
mse(dat$`Climate change`, dat$pred)
mse(dat$`Climate change`, dat$pred_cap)
plot(`Climate change`~pred_cap, data=dat)

summary(lm(`Climate change`~pred_cap, data=dat))

zero_labels = subset(dat, `Climate change` == 0)
hundred_labels = subset(dat, `Climate change` == 1)


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
