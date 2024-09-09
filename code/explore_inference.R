list.of.packages <- c("data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd = "~/git/osf-climate-nlp/"
setwd(wd)

mse = function(x, p){return(mean((x-p)^2))}

dat = fread("output/wb_regression_inference.csv")

dat$pred_cap = pmax(dat$pred, 0)
dat$pred_cap = pmin(dat$pred_cap, 1)

mse(dat$`Climate change`, dat$pred)
mse(dat$`Climate change`, dat$pred_cap)
plot(`Climate change`~pred_cap, data=dat)

summary(lm(`Climate change`~pred_cap, data=dat))
