# make_map_sf.R -- port of the author's Analysis/make_map.R (Figure 1 A/B and Figure A.5)
#
# The original script relies on rgdal::readOGR, rgeos::gCentroid and
# ggplot2::fortify(region=) (which needs maptools + rgeos). rgdal, rgeos and
# maptools were archived from CRAN in 2023 and do not build on R 4.5 without
# system GDAL/GEOS libraries, so this port swaps only the spatial I/O layer:
#   readOGR            -> sf::st_read
#   gCentroid(byid=T)  -> sf::st_centroid (planar, s2 off, same as GEOS centroid)
#   fortify(region=id_1) -> dissolve by id_1 (sf::st_union) and convert the
#                          polygon rings to a long/lat/group/order data frame
# Everything else (data merges, radii, legends, ggsave targets) is copied verbatim.
#
# usage: Rscript Program/make_map_sf.R  (run after Analysis.do section 1 created
#        Data/Intermediate/China_map_*.csv); outputs go to Results/Figures/.

suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(sf); library(scatterpie)
})
sf_use_s2(FALSE)

args <- commandArgs(trailingOnly = FALSE)
here <- dirname(normalizePath(sub("--file=", "", args[grep("--file=", args)])))
setwd(file.path(here, "_root"))       # _root/{Data,Output} as in the author's layout
out <- function(f) file.path(here, "..", "Results", "Figures", f)

## make map prefectures with AI and surveillance
data <- read.csv('Data/Intermediate/China_map_data.csv') %>% filter(police > 0)

shp <- st_read("Data/map_prefecture_2015/nt024fn0432.shp", quiet = TRUE)
cent <- suppressWarnings(st_coordinates(st_centroid(st_geometry(shp))))
shp_data <- st_drop_geometry(shp)

prefec_data <- shp_data %>%
  mutate(long = cent[,1], lat = cent[,2]) %>%
  rename(prov_eng = name_1, pref_eng = name_2) %>%
  right_join(data, by = c('prov_eng','pref_eng')) %>%
  mutate(high = unrest, low = 1 - unrest,
         log_ai = log(1+police)/6,
         log_unrest = log((1+event)*4)/6,
         one = 1, zero = 0)

# province background: equivalent of fortify(provinces, region = "id_1")
prov <- shp %>% group_by(id_1) %>% summarise(geometry = st_union(geometry), .groups = "drop")
rings <- st_cast(st_cast(prov, "MULTIPOLYGON"), "POLYGON")
coords <- as.data.frame(st_coordinates(rings))    # X Y L1 (ring) L2 (polygon)
prov_point <- coords %>%
  mutate(long = X, lat = Y,
         group = paste(L2, L1, sep = "."),
         order = row_number(), id = as.character(row_number())) %>%
  filter(as.numeric(id) %% 10 == 0)

theme_blank <- theme(axis.line=element_blank(),axis.text.x=element_blank(),
        axis.text.y=element_blank(),axis.ticks=element_blank(),
        axis.title.x=element_blank(), axis.title.y=element_blank(),
        panel.background=element_blank(),panel.border=element_blank(),panel.grid.major=element_blank(),
        panel.grid.minor=element_blank(),plot.background=element_blank())

p <- ggplot(data = prov_point, aes(x=long, y=lat, group = group)) +
  geom_polygon(fill="white") + coord_equal() + geom_path(color="gray") +
  geom_scatterpie(data = prefec_data, aes(x = long, y = lat, r = log_ai),
                  cols = c("high", "low"), legend_name = "Unrest") +
  theme_blank + labs(colour = "Surveillance Capacity") +
  scale_size_continuous(range = c(.4,5)) +
  scale_fill_manual(values = c("#132B43","#56B1F7")) +
  geom_scatterpie_legend(radius=c(0,.5,1.2543),x=130,y=22,n=3,labeller=function(x) round(exp(6*x)) )
ggsave(out("Figure1_mapB.pdf"), p)

p <- ggplot(data = prov_point, aes(x=long, y=lat, group = group)) +
  geom_polygon(fill="white") + coord_equal() + geom_path(color="gray") +
  geom_scatterpie(data = prefec_data, aes(x = long, y = lat, r = log_unrest),
                  cols = c("one", "zero"), legend_name = "Unrest") +
  theme_blank + labs(colour = "Surveillance Capacity") +
  scale_size_continuous(range = c(.4,5)) +
  scale_fill_manual(values = c("#132B43","#56B1F7")) +
  geom_scatterpie_legend(radius=c(0,.61718,1.2606),x=130,y=22,n=3,labeller=function(x) round(exp(6*x)/4) )
ggsave(out("Figure1_mapA.pdf"), p)

prov_names <- c("吉林省"="Jilin","四川省"="Sichuan","宁夏回族自治区"="Ningxia Hui","安徽省"="Anhui",
  "山东省"="Shandong","山西省"="Shanxi","广东省"="Guangdong","广西壮族自治区"="Guangxi","江苏省"="Jiangsu",
  "江西省"="Jiangxi","河北省"="Hebei","河南省"="Henan","浙江省"="Zhejiang","海南省"="Hainan","湖北省"="Hubei",
  "湖南省"="Hunan","甘肃省"="Gansu","福建省"="Fujian","贵州省"="Guizhou","陕西省"="Shaanxi","青海省"="Qinghai",
  "黑龙江省"="Heilongjiang")
pdata <- data %>% filter(merge_pref == "") %>%
  mutate(prov_eng = ifelse(province %in% names(prov_names), prov_names[province], prov_eng),
         policeprov = police) %>%
  select(prov_eng, policeprov)

prov_data <- shp_data %>%
  mutate(long = cent[,1], lat = cent[,2]) %>%
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

p <- ggplot(data = prov_point, aes(x=long, y=lat, group = group)) +
  geom_polygon(fill="white") + coord_equal() + geom_path(color="gray") +
  geom_scatterpie(data = prov_data, aes(x = long, y = lat, r = log_ai),
                  cols = c("high", "low"), legend_name = "Unrest") +
  theme_blank + labs(colour = "Surveillance Capacity") +
  scale_size_continuous(range = c(.4,5)) +
  scale_fill_manual(values = c("#132B43","#56B1F7")) +
  geom_scatterpie_legend(radius=c(0,.5,1.2543),x=130,y=22,n=3,labeller=function(x) round(exp(6*x)) )
ggsave(out("FigureA5_map.pdf"), p)
cat("maps written\n")
