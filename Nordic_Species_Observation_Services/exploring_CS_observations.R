##-------------------------------------------------------------------------------
# Exploring data from Artsobservasjoner and Artobservasjoner
##-------------------------------------------------------------------------------
library(ggplot2)


occ <- readRDS('data/GBIF_download_Norge.rds')

# Bar plot of different species
species_counts <- count(occ, vars = species, sort = TRUE)

ggplot(species_counts[1:12,], aes(x = vars, y = n, fill = vars)) + 
  geom_bar(stat = "identity", color="black") + 
  geom_text(aes(label = n), vjust=-0.3, color="black", size=4) +
  theme_light() + 
  ylab("Number of observations") +
  theme(text = element_text(size = 15), 
        axis.text.x = element_text(angle = 45, hjust = 1),
        axis.title.x = element_blank())

# Bar plot of years
time_counts_recent <- count(occ, year)

ggplot(time_counts_recent, aes(x = year, y = n)) + 
  geom_bar(stat = "identity", color="black", position = position_stack(reverse = FALSE)) + 
  theme_light() + 
  ylab("Number of observations")

##-------------------------------------------------------------------------------
# Looking only at Salmo trutta
##-------------------------------------------------------------------------------

trutta <- filter(occ, species == "Salmo trutta")

trutta_count <- count(trutta, year)
ggplot(trutta_count, aes(x = year, y = n)) + 
  geom_bar(stat = "identity", color="black", position = position_stack(reverse = FALSE)) + 
  theme_light() + 
  ylab("Number of observations")

# On the map:
norway <- ggplot2::map_data("world", region = "Norway(?!:Svalbard)") 
# Set theme for blue ocean
theme_set(theme_light() + theme(aspect.ratio = .70, panel.background = element_rect(fill = "aliceblue")))

ggplot(trutta) +
  geom_map(data = norway, map = norway, aes(long, lat, map_id=region), 
           color="#2b2b2b", fill = "white") + 
  geom_point(aes(x = decimalLongitude, y = decimalLatitude), 
             alpha = 0.6, size = 1, color = 'darkslategray4') + 
  theme(axis.title.x = element_blank(), 
        axis.title.y = element_blank())

ggplot(trutta) +
  geom_polygon(data = norway, aes(long, lat, group = group), 
           color="#2b2b2b", fill = "white") + 
  stat_binhex(aes(x = decimalLongitude, y = decimalLatitude)) +
  theme(axis.title.x = element_blank(), 
        axis.title.y = element_blank())

