library(dplyr)
library(ggplot2)
library(sp)
library(rgeos)
library(scatterpie)

##### MODIFY THE LINE BELOW WITH YOUR PATH TO THE REPLICATION FOLDER  
setwd('~/Dropbox/Polecon_AI/Analysis/Replication') 

## make map prefectures with AI and surveillance

# cleaned dataset
data <- read.csv('Data/Intermediate/China_map_data.csv') %>% 
  filter(police > 0)

# prefectures to centroid points
prefectures <- rgdal::readOGR("Data/map_prefecture_2015/nt024fn0432.shp")
prefectures@data <- prefectures@data 
centroids <- gCentroid(prefectures, byid = TRUE)

# merge data
prefec_data <- prefectures@data %>%
  mutate(long = centroids@coords[,1],
         lat =  centroids@coords[,2]) %>%
  rename(prov_eng = name_1, pref_eng = name_2) %>%
  right_join(data, by = c('prov_eng','pref_eng')) %>%
  mutate(high = unrest, low = 1 - unrest,
         log_ai = log(1+police)/6,
         log_unrest = log((1+event)*4)/6,
         one = 1, zero = 0)

# province background shapefile
provinces <- rgdal::readOGR("Data/map_prefecture_2015/nt024fn0432.shp")

prov_point <- fortify(provinces, region = "id_1")
prov_point <- prov_point %>%
  mutate(id = rownames(prov_point)) %>%
  filter(as.numeric(id) %% 10 == 0)


# pie chart version
ggplot(data = prov_point, aes(x=long, y=lat, group = group)) +
  geom_polygon(fill="white") +
  coord_equal() +
  geom_path(color="gray") +
  geom_scatterpie(data = prefec_data, aes(x = long, y = lat, r = log_ai),
                  cols = c("high", "low"), legend_name = "Unrest") +
  theme(axis.line=element_blank(),axis.text.x=element_blank(),
        axis.text.y=element_blank(),axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),plot.background=element_blank()) +
  labs(colour = "Surveillance Capacity") +
  scale_size_continuous(range = c(.4,5)) +
  scale_fill_manual(values = c("#132B43","#56B1F7")) +
  geom_scatterpie_legend(radius=c(0,.5,1.2543),x=130,y=22,n=3,labeller=function(x) round(exp(6*x)) )

ggsave("Output/Figure1_mapB.pdf")




 # pie chart version
ggplot(data = prov_point, aes(x=long, y=lat, group = group)) +
  geom_polygon(fill="white") +
  coord_equal() +
  geom_path(color="gray") +
  geom_scatterpie(data = prefec_data, aes(x = long, y = lat, r = log_unrest),
                  cols = c("one", "zero"), legend_name = "Unrest") +
  theme(axis.line=element_blank(),axis.text.x=element_blank(),
        axis.text.y=element_blank(),axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),plot.background=element_blank()) +
  labs(colour = "Surveillance Capacity") +
  scale_size_continuous(range = c(.4,5)) +
  scale_fill_manual(values = c("#132B43","#56B1F7")) +
  geom_scatterpie_legend(radius=c(0,.61718,1.2606),x=130,y=22,n=3,labeller=function(x) round(exp(6*x)/4) )


ggsave("Output/Figure1_mapA.pdf")


# cleaned dataset
pdata <- data %>%
  filter(merge_pref == "") %>%
  mutate(prov_eng = ifelse(province == "吉林省", "Jilin", prov_eng),
         prov_eng = ifelse(province == "四川省", "Sichuan", prov_eng),
         prov_eng = ifelse(province == "宁夏回族自治区", "Ningxia Hui", prov_eng),
         prov_eng = ifelse(province == "安徽省", "Anhui", prov_eng),
         prov_eng = ifelse(province == "山东省", "Shandong", prov_eng),
         prov_eng = ifelse(province == "山西省", "Shanxi", prov_eng),
         prov_eng = ifelse(province == "广东省", "Guangdong", prov_eng),
         prov_eng = ifelse(province == "广西壮族自治区", "Guangxi", prov_eng),
         prov_eng = ifelse(province == "江苏省", "Jiangsu", prov_eng),
         prov_eng = ifelse(province == "江西省", "Jiangxi", prov_eng),
         prov_eng = ifelse(province == "河北省", "Hebei", prov_eng),
         prov_eng = ifelse(province == "河南省", "Henan", prov_eng),
         prov_eng = ifelse(province == "浙江省", "Zhejiang", prov_eng),
         prov_eng = ifelse(province == "海南省", "Hainan", prov_eng),
         prov_eng = ifelse(province == "湖北省", "Hubei", prov_eng),
         prov_eng = ifelse(province == "湖南省", "Hunan", prov_eng),
         prov_eng = ifelse(province == "甘肃省", "Gansu", prov_eng),
         prov_eng = ifelse(province == "福建省", "Fujian", prov_eng),
         prov_eng = ifelse(province == "贵州省", "Guizhou", prov_eng),
         prov_eng = ifelse(province == "陕西省", "Shaanxi", prov_eng),
         prov_eng = ifelse(province == "青海省", "Qinghai", prov_eng),
         prov_eng = ifelse(province == "黑龙江省", "Heilongjiang", prov_eng),
         policeprov = police) %>%
  select(prov_eng, policeprov)

# merge data
prov_data <- prefectures@data %>%
  mutate(long = centroids@coords[,1],
         lat =  centroids@coords[,2]) %>%
  rename(prov_eng = name_1, pref_eng = name_2) %>%
  right_join(data, by = c('prov_eng','pref_eng')) %>%
  mutate(high = unrest, low = 1 - unrest) %>%
  group_by(prov_eng) %>%
  summarise(long = mean(long, na.rm= TRUE ), lat = mean(lat, na.rm=TRUE), nprefs= length(prov_eng),
            police = sum(police), unrest = mean(unrest)) %>%
  left_join(pdata, by = c('prov_eng')) %>%
  mutate(extra = policeprov*nprefs,
         police = ifelse(!is.na(extra),police + extra,police),
         high = unrest, low = 1 - high, log_ai = log(police)/6)

# pie chart version
ggplot(data = prov_point, aes(x=long, y=lat, group = group)) +
  geom_polygon(fill="white") +
  coord_equal() +
  geom_path(color="gray") +
  geom_scatterpie(data = prov_data, aes(x = long, y = lat, r = log_ai),
                  cols = c("high", "low"), legend_name = "Unrest") +
  theme(axis.line=element_blank(),axis.text.x=element_blank(),
        axis.text.y=element_blank(),axis.ticks=element_blank(),
        axis.title.x=element_blank(),
        axis.title.y=element_blank(),
        panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),plot.background=element_blank()) +
  labs(colour = "Surveillance Capacity") +
  scale_size_continuous(range = c(.4,5)) +
  scale_fill_manual(values = c("#132B43","#56B1F7")) +
  geom_scatterpie_legend(radius=c(0,.5,1.2543),x=130,y=22,n=3,labeller=function(x) round(exp(6*x)) )

ggsave("Output/FigureA5_map.pdf")

