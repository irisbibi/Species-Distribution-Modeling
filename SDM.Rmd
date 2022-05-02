---
title: "Species Distribution Modeling for Kit Foxes and the Sierra Nevada Red Fox"
author: "Iris Zhang"
date: "04/27/2020"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# **Kit Fox (*Vulpes macrotis*) Species Distribution Modelling Under Current and Future Climates** 

## Install Required Packages
```{r}
#install.packages("rgbif")
#install.packages("ggplot2")
#install.packages("raster")
#install.packages("rasterVis")
#install.packages("maps")
#install.packages("dismo")
#install.packages("rgdal")
```

## Download Kit Fox species observations from Global Biodiversity Information Facility
```{r}
library(rgbif)

Species.Name <- "Vulpes macrotis"

#Search GBIF and download observations
Species.key <- name_backbone(name=Species.Name)$speciesKey
locations <- occ_search(taxonKey=Species.key,
                              decimalLatitude = '30,50',
                              decimalLongitude='-130,-75',
                              hasCoordinate = TRUE,
                              return='data', limit=5000)


#Remove localities with uncertain coordinates - meaning the observer entered approximate latitude and longitude data. This is common with very old specimens/records that were collected prior to handheld GPS devices being invented
locations <- subset(locations, coordinateUncertaintyInMeters <= 5000)
head(locations)
```

### Simplify the dataset
```{r}
locations.sub <- locations[,c("species", "decimalLongitude", "decimalLatitude")]

#rename the headers on each column to make our commands easier below
colnames(locations.sub) <- c("Species", "Longitude", "Latitude")

#Save  dataset as a .csv file on your computer
write.csv(locations.sub, "Locations_KF.csv", quote=F, row.names=F)

```

## Create a Map
```{r}
library(ggplot2)
# Download Country Boundaries
#install.packages("maps")
world <- map_data("world")
```


### Plot observation of kit fox localities on a map (West Coast)

```{r}

map <- ggplot()+
  geom_polygon(data=world, aes(x=long, y=lat, group=group), color='grey40', fill='transparent', size=0.25)+
  geom_point(data=locations.sub, aes(x=Longitude, y=Latitude), size = 2, alpha =0.75) +
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)

map

ggsave("LocationsMap.jpg", height=5, width=7, units="in", dpi=600)
```

## Download the environmental predictor variables from https://worldclim.org/data/bioclim.html
- We downloaded 19 different climate variables that describe variation in temperature and precipitation
- This dataset has data for every ~4.5 km x 4.5 km pixel for the entire world (only terrestrial areas)
- The object "predictors" will include 19 different objects with the climate data shown spatially for each of the 19 climate variables
```{r}
library(raster)

#describe the extent for which we want to download data
e <- extent(c(-125, -110, 32, 43)) ## min longitude, max longitude, min latitude, max latitude

#download the data for our region of interest
bioclim <- getData('worldclim', var='bio',  res=2.5) ## change this command from what we did in lab 8, we have increased the resolution, which allows us to download the full global dataset


#crop the dataset to just the coordinates we are interested in
predictors <- crop(bioclim, e)

#plot all of the variables
plot(predictors)
```

### Save all of the predictor variable files to your computer
```{r}
#create a folder called "Predictors"
dir.create("Predictors", showWarnings = F)

#run a for loop to save all 19 .asc files
for(i in 1:19){
  file.name <- paste0("Predictors/", names(predictors[[i]]), ".asc")
  writeRaster(predictors[[i]],file.name, overwrite=T)
}
```

## Create a Folder to save your Maxent Results
```{r}
dir.create("Maxent Output", showWarnings = F)
```

## Plot Maxent Results in R for Kit Foxes
```{r}
library(rasterVis)

#Change your Species.Name object so that it has an underscore rather than a space in between genus and species (E.g, Canis latrans changes to Canis_latrans). This will make it possible to opben the .asc file that Maxent created
Species_Name <- gsub(" ", "_", Species.Name)

SDM.1 <- raster(paste0("Maxent Output/",Species_Name, ".asc"))

##Plot your SDM on a map with the outlines to the countries and the observation localities
map <- gplot(SDM.1, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("SDM_KitFox_Current.jpg", height=5, width=7, units="in", dpi=600)
```


## Create RCP 2.6 and 8.5 Data Layers
### RCP 2.6 and 8.5 data layers allow us to create species distribution models of kit foxes in future climate scenarios
```{r}
#install.packages("rgdal")
library(raster)
predictors.26 <- getData('CMIP5', var='bio', res=2.5, rcp=26, model='MI', year=50)
predictors.26 <- crop(predictors.26, e)
names(predictors.26) <- names(predictors)

plot(predictors.26)

### Save RCP 2.6 Predictor variables
#create a folder called "Predictors"
dir.create("Data Layers RCP 26", showWarnings = F)

#run a for loop to save all 19 .asc files
for(i in 1:19){
  file.name <- paste0("Data Layers RCP 26/", names(predictors.26[[i]]), ".asc")
  writeRaster(predictors.26[[i]],file.name, overwrite=T)
}

predictors.85 <- getData('CMIP5', var='bio', res=2.5, rcp=85, model='MI', year=50)
predictors.85 <- crop(predictors.85, e)
names(predictors.85) <- names(predictors)

plot(predictors.85)

### Save RCP 8.5 Predictor variables
#create a folder called "Predictors"
dir.create("Data Layers RCP 85", showWarnings = F)

#run a for loop to save all 19 .asc files
for(i in 1:19){
  file.name <- paste0("Data Layers RCP 85/", names(predictors.85[[i]]), ".asc")
  writeRaster(predictors.85[[i]],file.name, overwrite=T)
}
```

## Plot RCP 2.6 Conditions for Kit Foxes
```{r}
library(rasterVis)
library(ggplot2)
Species_Name <- gsub(" ", "_", Species.Name)

SDM.26 <- raster(paste0("Maxent Output RCP 26/",Species_Name, "_Data Layers RCP 26.asc"))

##Plot SDM on a map with the outlines to the countries and the observation localities
map <- gplot(SDM.26, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("SDM_RCP26_KitFox.jpg", height=5, width=7, units="in", dpi=600)
```


## Plot RCP 8.5 Conditions for Kit Foxes
```{r}
library(rasterVis)

Species_Name <- gsub(" ", "_", Species.Name)

SDM.85 <- raster(paste0("Maxent Output RCP 85/",Species_Name, "_Data Layers RCP 85.asc"))

##Plot SDM on a map with the outlines to the countries and the observation localities
map <- gplot(SDM.85, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("SDM_RCP85_KitFox.jpg", height=5, width=7, units="in", dpi=600)
```

#Compare niche overlap between current SDM and future SDMs under RCP conditions as well as future SDMs to each other for kit fox populations
```{r}
#install.packages("dismo")
library(dismo)

#Calculate niche overlap using Schoener's D.
nicheOverlap(SDM.1, SDM.26, stat = "D")
nicheOverlap(SDM.1, SDM.85, stat = "D")
nicheOverlap(SDM.26, SDM.85, stat = "D")

#Values close to 1 = a lot of overlap, values close to 0 = little overlap
```

# **Sierra Nevada Red Fox (*Vulpes vulpes*) Species Distribution Modelling Under Current and Future Climates** 

## Put in the name of the species
- Enter the scientific name
```{r}
Species.Name <- "Vulpes vulpes"
```

## Download species observation data
- First we downloaded latitude and longitude data for the species from the online database www.gbif.org, the Global Biodiversity Information Facility.
```{r}
library(rgbif)

#Search GBIF and download observations
Species.key <- name_backbone(name=Species.Name)$speciesKey
locations <- occ_search(taxonKey=Species.key,
                              decimalLatitude = '32,43',
                              decimalLongitude='-125,-110',
                              hasCoordinate = TRUE,
                              return='data', limit=5000)


#Remove localities with uncertain coordinates
locations <- subset(locations, coordinateUncertaintyInMeters <= 5000)
head(locations)
```

### Simplify the dataset
- We removed all other columns in the dataset and save only three columns that are needed for analyses.
```{r}
locations.sub <- locations[,c("species", "decimalLongitude", "decimalLatitude")]

#Rename the headers on each column to make our commands easier below
colnames(locations.sub) <- c("Species", "Longitude", "Latitude")

#Save dataset as a .csv file on our computers
write.csv(locations.sub, "Locations_SN.csv", quote=F, row.names=F)

```

### Plot our observation localities on a map
- This plot shows where our species has been observed with political boundaries for the region of interest

```{r}
library(ggplot2)
map <- ggplot()+
  geom_polygon(data=world, aes(x=long, y=lat, group=group), color='grey40', fill='transparent', size=0.25)+
  geom_point(data=locations.sub, aes(x=Longitude, y=Latitude), size = 2, alpha =0.75) +
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)

map

ggsave("Locations Map for Sierra Nevada Fox.jpg", height=5, width=7, units="in", dpi=600)
```


## Create a Folder to save our Maxent Results
```{r}
dir.create("Maxent Output 2", showWarnings = F)
```

## Plot our Maxent Results in R
- After we have run Maxent, open up the SDM that Maxent created

```{r}
library(rasterVis)

#Change our Species.Name object so that it has an underscore rather than a space in between genus and species. This will make it possible to opben the .asc file that Maxent created
Species_Name <- gsub(" ", "_", Species.Name)

SDM <- raster(paste0("Maxent Output 2/",Species_Name, ".asc"))

##Plot our SDM on a map with the outlines to the countries and the observation localities
map <- gplot(SDM, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("Sierra Nevada Red Fox.jpg", height=5, width=7, units="in", dpi=600)
```

##Plot SDM26 on a map with the outlines to the countries and the observation localities
```{r}

SDM26 <- raster(paste0("Maxent Output RCP 26 2/",Species_Name, "_Data Layers RCP 26.asc"))

map <- gplot(SDM26, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("SDM26_SierraFox.jpg", height=5, width=7, units="in", dpi=600)

```

##Plot SDM85 on a map with the outlines to the countries and the observation localities
```{r}
SDM85 <- raster(paste0("Maxent Output RCP 85 2/",Species_Name, "_Data Layers RCP 85.asc"))

map <- gplot(SDM85, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("SDM85_SierraFox.jpg", height=5, width=7, units="in", dpi=600)

```

## Compare SDMs of Sierra Nevada Red Fox to calculate the overlapping area
```{r}
library(dismo)

#calculate niche overlap using Schoener's D. 
nicheOverlap(SDM, SDM26, stat = "D")
nicheOverlap(SDM, SDM85, stat = "D")
nicheOverlap(SDM26, SDM85, stat = "D")

#values close to 1 = a lot of overlap, values close to 0 = little overlap
```
