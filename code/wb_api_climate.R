# Setup ####
list.of.packages <- c("data.table", "rstudioapi", "jsonlite")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)) install.packages(new.packages)
lapply(list.of.packages, require, character.only=T)

wd <- dirname(getActiveDocumentContext()$path) 
setwd(wd)
setwd("../")

select_sectors = c(
  "Climate change", "Adaptation", "Mitigation"
)

parse_projects = function(projects, select_sectors){
  proj_list = list()
  proj_index = 1

  for(i in 1:length(projects)){
    project = projects[[i]]
    themes = project$theme_list
    project$theme_list = NULL
    theme2s = rbindlist(themes$theme2, fill=T)
    if("theme2" %in% names(themes)){
      themes$theme2 = NULL
    }
    
    theme3s = rbindlist(theme2s$theme3, fill=T)
    
    if("theme3" %in% names(theme2s)){
      theme2s$theme3 = NULL
    }
    
    all_themes = rbindlist(list(
      themes, theme2s, theme3s
    ), fill=T)
    theme_sum = 0
    if(nrow(all_themes) > 0){
      theme_sum = sum(as.numeric(all_themes$percent), na.rm=T)
    }
    if("name" %in% names(all_themes)){
      all_themes = subset(all_themes, name %in% select_sectors)
    }
    
    proj_dat = data.frame(project)
    if(nrow(all_themes) > 0){
      for(j in 1:nrow(all_themes)){
        theme = all_themes[j,]
        theme_name = theme$name
        theme_pct = theme$percent
        proj_dat[,theme_name] = theme_pct
      }
    }
    
    # Only add if project has any sectors
    if(theme_sum > 0){
      proj_list[[proj_index]] = proj_dat
      proj_index = proj_index + 1
    }
  }
  
  all_proj_dat = rbindlist(proj_list, fill=T)
  
  return(all_proj_dat)
}

rows = 500

base_url = "https://search.worldbank.org/api/v3/projects?format=json&fl=id,fiscalyear,project_name,project_abstract,pdo,theme_list&apilang=en&rows="

expected_length = as.numeric(
  fromJSON(
    paste0(base_url, "0")
  )$total
)

expected_pages = ceiling(expected_length / 500)

data_list = list()

pb = txtProgressBar(max=expected_pages, style=3)
offset = 0
for(i in 1:expected_pages){
  setTxtProgressBar(pb, i)
  page_url = paste0(base_url, rows, "&os=", offset)
  results = fromJSON(page_url)
  projects = results$projects
  all_proj_dat = parse_projects(projects, select_sectors)
  data_list[[i]] = all_proj_dat
  offset = offset + 500
}

wb_climate = rbindlist(data_list, fill=T)
wb_climate = wb_climate[,c(
  "id", "proj_id", "fiscalyear", "project_name", "pdo", "project_abstract",
  select_sectors
),with=F]

for(sector in select_sectors){
  wb_climate[which(is.na(wb_climate[,sector,with=F])),sector] = 0
  wb_climate[,sector] = as.numeric(wb_climate[,sector,with=F][[1]]) / 100
}

fwrite(wb_climate, "input/wb_api_climate_percentages.csv")
