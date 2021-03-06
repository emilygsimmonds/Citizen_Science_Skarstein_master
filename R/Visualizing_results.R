# All exploration of model and results

library(ggpubr)
library(colorspace)
library(patchwork)
library(raster)
library(blockCV)

# Loading covariates and observations
source("R/loading_map_obs_covs.R")

# Model visualization functions
source("R/Model_visualization_functions.R")

# From "full_paralell_CV.R":
res_cv <- readRDS("R/output/cv_output_4mods.RDS")

# Setting fish species
fish_sp <- "trout"

# From "full_model.R":
model_final <- readRDS(paste0("R/output/model_", fish_sp, ".RDS"))
#model_final <- readRDS(paste0("R/output/model_", fish_sp, "_100range.RDS"))

# Prediction stack:
stk.pred <- readRDS("R/output/stkpred.RDS")

if(fish_sp == "trout"){
  full_name <- "Brown trout"
}else if(fish_sp == "perch"){
  full_name <- "European perch"
}else if(fish_sp == "char"){
  full_name <- "Arctic char"
}else{
  full_name <- "European pike"
}

#----------------------------------------------------------------------------

# CROSS VALIDATION FOLDS
validation_raster <- brick(SpatialPixelsDataFrame(points=stk.pred$predcoords, data=data.frame(rep(1, 6005)), proj4string=Projection))
k <- 5
sb <- spatialBlock(speciesData = trout_survey, # sf or SpatialPoints
                   species = "occurrenceStatus", # the response column (binomial or multi-class)
                   rasterLayer = validation_raster, # a raster for background (optional)
                   theRange = 150000, # size of the blocks in meters
                   k = k, # number of folds
                   selection = "random",
                   iteration = 100, # find evenly dispersed folds
                   biomod2Format = FALSE)
sb$plots + scale_fill_continuous_sequential(palette = "Teal")

ggsave("figs/cv_folds.pdf", width = 5)




# OUTPUT FROM CROSS VALIDATION ----
res_matrix <- res_cv %>% unlist() %>% matrix(ncol = 5)
row.names(res_matrix) <- c("dev0", "dev1", "dev2", "dev3", "dev4")
res_matrix
rowMeans(res_matrix)

# Results when using six models
#    dev0     dev1     dev2     dev3     dev4     dev5 
#89.63066 12.98962 12.92028 13.00012 12.93050 12.91507


# RANDOM FIELDS ----
spat_fields_df <- proj_random_field(model_final$model, sp_polygon = norway.poly, 
                                    mesh = Mesh$mesh)
spat_fields <- spat_fields_df %>% tidyr::gather(key = statistic, value = value, mean:sd)

# New labels for statistics variable
statistic.labs <- c("Mean", "Standard deviation")
names(statistic.labs) <- c("mean", "sd")

# New labels for field variable
field.labs <- c("Second spatial field (PO data only)", "First spatial field (both data sets)")  
names(field.labs) <- c("bias", "shared")

shared_p <- ggplot(spat_fields %>% filter(field == "shared")) +
  geom_raster(aes(x = decimalLongitude, y = decimalLatitude, fill = value)) +
  #scale_fill_viridis(option = "magma", direction = -1) +
  scale_fill_continuous_sequential(palette = "BuPu")  +
  facet_grid(rows = vars(statistic),
             labeller = labeller(field = field.labs, statistic = statistic.labs)) +
  geom_polygon(data = norway, aes(long, lat, group = group), 
               color="black", fill = NA) + coord_quickmap() + 
  theme_bw() +
  theme(axis.title = element_blank(), legend.position = "left",
        strip.background = element_blank(), strip.text.y = element_blank(),
        legend.title = element_blank()) +
  ggtitle(expression(paste("First spatial field, ", xi[1]))) 

bias_p <- ggplot(spat_fields%>% filter(field == "bias")) +
  geom_raster(aes(x = decimalLongitude, y = decimalLatitude, fill = value)) +
  #scale_fill_viridis(option = "viridis", direction = -1) +
  scale_fill_continuous_sequential(palette = "GnBu")  +
  facet_grid(rows = vars(statistic),
             labeller = labeller(field = field.labs, statistic = statistic.labs)) +
  geom_polygon(data = norway, aes(long, lat, group = group), 
               color="black", fill = NA) + coord_quickmap() + 
  theme_bw() +
  theme(axis.title = element_blank(), axis.ticks.y = element_blank(), 
        axis.text.y = element_blank(), legend.title = element_blank()) + 
  ggtitle(expression(paste("Effort field, ", xi[2])))

shared_p + bias_p

ggsave(paste0("figs/spatial_fields_", fish_sp, ".pdf"), width = 6.6, height = 5.7)




# DOTS AND WHISKERS PLOTS ----
Use <- c("decimalLongitude","decimalLatitude", "log_area", 
         "log_catchment", "eurolst_bio10", "SCI")
cov.labs <- c("Longitude", "Latitude", "Log area", "Log catchment", 
              "Temperature", "Shoreline complexity index")

dots_whiskers_inla(model_final) + scale_y_discrete(labels = cov.labs) +
  ggtitle(paste0(full_name))

ggsave(paste0("figs/coefficient_plot_", fish_sp, ".pdf"), height = 2.5, width = 5) 



# PREDICTIONS ----
Pred <- prediction_df(stk.pred = stk.pred, model = model_final)
Pred_mean <- Pred %>% filter(statistic=="mean")
Pred_sd <- Pred %>% filter(statistic=="stddev")
limit_mean <- max(abs(Pred_mean$value)) * c(-1, 1)
limit_sd <- max(abs(Pred_sd$value)) * c(0, 1)

p_mean <- ggplot(Pred_mean) +
  geom_raster(aes(x = decimalLongitude, y = decimalLatitude, fill = value)) +
  #scale_fill_gradientn(colours = c("darkorange2", "white", "darkorchid4")) + 
  #scale_fill_continuous_diverging(palette = "Purple-Green", limit = limit_mean)  +
  scale_fill_continuous_sequential(palette = "PuBuGn")  +
  geom_polygon(data = norway, aes(long, lat, group = group), 
               color='black', fill = NA) + coord_quickmap() +
  ggtitle(label = "Mean") +
  labs(fill = element_blank()) + 
  theme_bw() + theme(axis.title = element_blank(), plot.title = element_text(hjust = 0.5))

p_sd <- ggplot(Pred_sd) +
  geom_raster(aes(x = decimalLongitude, y = decimalLatitude, fill = value)) +
  #scale_fill_continuous_diverging(palette = "Purple-Green", limit = limit_sd)  +
  #scale_fill_gradientn(colours = c("white", "darkorchid4")) + 
  scale_fill_continuous_sequential(palette = "Reds 3")  +
  geom_polygon(data = norway, aes(long, lat, group = group), 
               color='black', fill = NA) + coord_quickmap() + 
  ggtitle(label = "Standard deviation") +
  labs(fill = element_blank()) +
  theme_bw() + theme(axis.title = element_blank(), plot.title = element_text(hjust = 0.5))

p_mean + p_sd

ggsave(paste0("figs/posterior_predictions_", fish_sp, ".pdf"), height = 4, width = 7)

# Plotting intensity instead of log intensity (but what do we do with sd then?)

ggplot(Pred_mean) +
  geom_raster(aes(x = decimalLongitude, y = decimalLatitude, fill = exp(value))) +
  #scale_fill_continuous_diverging(palette = "Purple-Green", limit = limit_mean)  +
  scale_fill_viridis(option = "inferno", direction = -1) +
  geom_polygon(data = norway, aes(long, lat, group = group), 
               color='black', fill = NA) + coord_quickmap() +
  theme_bw() + theme(axis.title = element_blank()) +
  ggtitle("Predicted posterior intensity (mean)")

# Plotting only mean 
ggplot(Pred_mean) +
  geom_raster(aes(x = decimalLongitude, y = decimalLatitude, fill = value), show.legend = FALSE) +
  scale_fill_continuous_sequential(palette = "PuBuGn")  +
  geom_polygon(data = norway, aes(long, lat, group = group), 
               color='black', fill = NA) + coord_quickmap() +
  labs(fill = element_blank()) + 
  theme_bw() + theme(axis.title = element_blank(), axis.ticks = element_blank(), axis.text = element_blank())

ggsave("figs/minimal_prediction.png")

# POSTERIOR MARGINAL ----
shared <- dplyr::bind_rows(Range = as.data.frame(model_final$model$marginals.hyperpar[[1]]),
                           Stdev = as.data.frame(model_final$model$marginals.hyperpar[[2]]),
                                .id = "hyperpar")
bias <- dplyr::bind_rows(Range = as.data.frame(model_final$model$marginals.hyperpar[[3]]),
                         Stdev = as.data.frame(model_final$model$marginals.hyperpar[[4]]),
                               .id = "hyperpar")
hyperpars <- dplyr::bind_rows(shared_field = shared, bias_field = bias, .id = "field")

range_shared <- ggplot(hyperpars %>% filter(hyperpar == "Range", field == "shared_field")) + 
  geom_line(aes(x = x, y = y), color = "magenta4", lwd = 0.9) +
  ylab (expression(paste(pi, "(", rho, " | ", bold(y), ")"))) +
  ggtitle(expression(paste(rho, " - shared field"))) +
  theme_bw() + theme(aspect.ratio=1, legend.position = "none", axis.title.x = element_blank())

sigma_shared <- ggplot(hyperpars %>% filter(hyperpar == "Stdev", field == "shared_field")) + 
  geom_line(aes(x = x, y = y), color = "orange", lwd = 0.9) +
  ylab ("") +
  ggtitle(expression(paste(sigma, " - shared field"))) +
  theme_bw() + theme(aspect.ratio=1, legend.position = "none", axis.title.x = element_blank())

range_bias <- ggplot(hyperpars %>% filter(hyperpar == "Range", field == "bias_field")) + 
  geom_line(aes(x = x, y = y), color = "magenta4", lwd = 0.9) +
  ylab ("") +
  ggtitle(expression(paste(rho, " - bias field"))) +
  theme_bw() + theme(aspect.ratio=1, legend.position = "none", axis.title.x = element_blank())

sigma_bias <- ggplot(hyperpars %>% filter(hyperpar == "Stdev", field == "bias_field")) + 
  geom_line(aes(x = x, y = y), color = "orange", lwd = 0.9) +
  ylab ("") +
  ggtitle(expression(paste(sigma, " - bias field"))) +
  theme_bw() + theme(aspect.ratio=1, legend.position = "none", axis.title.x = element_blank())


(range_shared | range_bias) / (sigma_shared | sigma_bias) +
  plot_annotation(title = paste0(full_name, ": hyperparameters")) &
  theme(plot.title = element_text(hjust = 0.5, size = 14))

ggsave(paste0("figs/thetas_", fish_sp, ".pdf"))


summary(model_final$model)

