---
title: "Kit Fox"
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

## Install Required Packages
- Install the packages below if you don't already have them installed
- Make sure to put a hash in front of "install.packages" after you are done, so that it doesn't keep re-installing the packages every time you knit this document
```{r}
#install.packages("rgbif")
#install.packages("ggplot2")
#install.packages("raster")
#install.packages("rasterVis")
```

## Choose a species
- The species must live in southern California that you would like to study
- Enter the scientific name in the quotes below
```{r}
Species.Name <- "Vulpes macrotis"
```

## Download species observation data
- First we will download latitude and longitude data for our species from the online database www.gbif.org, the Global Biodiversity Information Facility.
```{r}
library(rgbif)

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
- All we need to run the analyses are the species name, longitude, and latitude. So we will remove all other columns in the dataset and save only these three columns
```{r}
locations.sub <- locations[,c("species", "decimalLongitude", "decimalLatitude")]

#rename the headers on each column to make our commands easier below
colnames(locations.sub) <- c("Species", "Longitude", "Latitude")

#Save your dataset as a .csv file on your computer
write.csv(locations.sub, "Locations.csv", quote=F, row.names=F)

```


## Create a Map
- Download political boundaries for the region of interest so that we can map our data

```{r}
library(ggplot2)
# Download Country Boundaries
#install.packages("maps")
world <- map_data("world")
```


### Plot your observation localities on a map
- This plot shows where your species has been observed with political boundaries for the region of interest

```{r}

map <- ggplot()+
  geom_polygon(data=world, aes(x=long, y=lat, group=group), color='grey40', fill='transparent', size=0.25)+
  geom_point(data=locations.sub, aes(x=Longitude, y=Latitude), size = 2, alpha =0.75) +
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)

map

ggsave("LocationsMap.jpg", height=5, width=7, units="in", dpi=600)
```
## Download the environmental predictor variables
- We will be downloading 19 different climate variables that describe variation in temperature and precipitation
- This dataset has data for every ~4.5 km x 4.5 km pixel for the entire world (only terrestrial areas)
- The object "predictors" will include 19 different objects with the climate data shown spatially for each of the 19 climate variables
- See here for a list of all the variables: https://worldclim.org/data/bioclim.html

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
plot(predictors[[14]])
```

### Save all of the predictor variable files to your computer
- These will save in a folder where your .RMD file is saved called "Predictors"
- In this folder, you will find 19 different .asc files (.asc is a type of text file)
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
---------------------------------------PAUSE-------------------------------------

## Run Maxent on your computer
- First, download the program Maxent here: https://biodiversityinformatics.amnh.org/open_source/maxent/
- In the folder that it downloads, open the "maxent.jar" file
  - You may need to give your computer permission to run this file
  - You may need to install Java or JDK to run this
- In Maxent:
  -	In the upper left box, select the new *Locations.csv file* that you just created
  -	In the upper right box, select *the Predictors folder* that contains all of the environmental data you just downloaded
    - Note: do not select the files in the folder, select the folder itself
  -	Check all three boxes on the right hand side
  -	For Output Directory, choose the *"Maxent Output" folder* to save the files Maxent creates
  -	Click settings:
    - Change “Random Test Percentage” to 20
    - This will create a training dataset with 80 percent of the observation data and a test dataset with 20 percent of the observation data
  -	Click run
    - If you get an error that some observations do not have environmental data, select "Supress Similar Warnings"
      - This just means that some of your points are outside the area where we have climate data
  -	After the run has completed, open up the .html file that Maxent created (saved in the folder "Maxent Output")
  -	Look at the AUC values for your training and test data
  -	Remember, AUC values close to 1 are great, AUC values near 0.5 mean your model is no better than random.


----------------------------------RETURN to R-------------------------------------

## Plot your Maxent Results in R
- After you have run Maxent, open up the SDM that Maxent created
- You will need to copy and paste the .asc file that Maxent created into the folder where this .RMD file is saved

```{r}

library(rasterVis)

#Change your Species.Name object so that it has an underscore rather than a space in between genus and species (E.g, Canis latrans changes to Canis_latrans). This will make it possible to opben the .asc file that Maxent created
Species_Name <- gsub(" ", "_", Species.Name)

SDM <- raster(paste0("Maxent Output/",Species_Name, ".asc"))

##Plot your SDM on a map with the outlines to the countries and the observation localities
map <- gplot(SDM, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("SDM.jpg", height=5, width=7, units="in", dpi=600)
```


** Repeat these next two chunks for rcp 8.5, but change rcp in the getData command**

## Create RCP 2.6 Data Layers
```{r}
#install.packages("rgdal")
library(raster)
predictors.26 <- getData('CMIP5', var='bio', res=2.5, rcp=26, model='MI', year=50)
predictors.26 <- crop(predictors.26, e)
names(predictors.26) <- names(predictors)

plot(predictors.26)
plot(predictors.26[[14]])

```

### Save all of the predictor variable files to your computer
- These will save in a folder where your .RMD file is saved called "Predictors"
- In this folder, you will find 19 different .asc files (.asc is a type of text file)
```{r}
#create a folder called "Predictors"
dir.create("Data Layers RCP 26", showWarnings = F)

#run a for loop to save all 19 .asc files
for(i in 1:19){
  file.name <- paste0("Data Layers RCP 26/", names(predictors.26[[i]]), ".asc")
  writeRaster(predictors.26[[i]],file.name, overwrite=T)
}

```

## Create RCP 8.5 Data Layers
```{r}
library(raster)
predictors.85 <- getData('CMIP5', var='bio', res=2.5, rcp=85, model='MI', year=50)
predictors.85 <- crop(predictors.85, e)
names(predictors.85) <- names(predictors)

plot(predictors.85)
plot(predictors.85[[14]])
```

```{r}
#create a folder called "Predictors"
dir.create("Data Layers RCP 85", showWarnings = F)

#run a for loop to save all 19 .asc files
for(i in 1:19){
  file.name <- paste0("Data Layers RCP 85/", names(predictors.85[[i]]), ".asc")
  writeRaster(predictors.85[[i]],file.name, overwrite=T)
}
```

## Plot RCP 26 Conditions 
```{r}
library(rasterVis)
library(ggplot2)

#Change your Species.Name object so that it has an underscore rather than a space in between genus and species (E.g, Canis latrans changes to Canis_latrans). This will make it possible to opben the .asc file that Maxent created
Species_Name <- gsub(" ", "_", Species.Name)

SDM.26 <- raster(paste0("Maxent Output RCP 26/",Species_Name, "_Data Layers RCP 26.asc"))

##Plot your SDM on a map with the outlines to the countries and the observation localities
map <- gplot(SDM, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("SDM_RCP26.jpg", height=5, width=7, units="in", dpi=600)
```


## Plot RCP 85 Conditions 
```{r}
library(rasterVis)

#Change your Species.Name object so that it has an underscore rather than a space in between genus and species (E.g, Canis latrans changes to Canis_latrans). This will make it possible to opben the .asc file that Maxent created
Species_Name <- gsub(" ", "_", Species.Name)

SDM.85 <- raster(paste0("Maxent Output RCP 85/",Species_Name, "_Data Layers RCP 85.asc"))

##Plot your SDM on a map with the outlines to the countries and the observation localities
map <- gplot(SDM, maxpixels = 100000) + 
  geom_tile(aes(fill = value))+
  scale_fill_viridis_c(option = "C", na.value = "transparent") + 
  theme_bw()+
  coord_fixed(xlim = c(-125, -110),  ylim = c(32, 43), ratio = 1.3)+
  xlab("Longitude")+
  ylab("Latitude")

map

ggsave("SDM_RCP85.jpg", height=5, width=7, units="in", dpi=600)
```


```{r}
install.packages("dismo")
library(dismo)

#calculate niche overlap using Schoener's D. You will need to have both SDMs saved with different object names (e.g., SDM.1 and SDM.2)
nicheOverlap(SDM, SDM.85, stat = "D")

#calculate niche overlap using Schoener's D. You will need to have both SDMs saved with different object names (e.g., SDM.1 and SDM.2)
nicheOverlap(SDM, SDM.26, stat = "D")

#calculate niche overlap using Schoener's D. You will need to have both SDMs saved with different object names (e.g., SDM.1 and SDM.2)
nicheOverlap(SDM.26, SDM.85, stat = "D")

#values close to 1 = a lot of overlap, values close to 0 = little overlap
```

