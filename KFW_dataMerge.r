
library(maptools)
library(reshape)
library(splitstackshape)
library(ggplot2)

#Session - Set Working Directory - To Source File Location
#File for the KFW analysis
shpfile = "input_data/terra_indigenaPolygon_id.shp"
src_Shp = readShapePoly(shpfile)


#Clean the source Shapefile to remove all but the matching column.
cln_Shp <- src_Shp[,c("id")]

#Population -------------------------------------------
GPW_pop <- "input_data/sciclone_extracts/GPW_extract_merge.csv"
GPW_pop <- read.csv(GPW_pop)
#Rename the columns for easier interpretation later..
colnames(GPW_pop)[2] <- "Pop_1990"
colnames(GPW_pop)[3] <- "Pop_1995"
colnames(GPW_pop)[4] <- "Pop_2000"
#Merge it in
kfw.SPDF <- merge(cln_Shp, GPW_pop, by.x="id", by.y="id")

#Add later population data from GPW4, file also includes nighttime lights 
# data was not available at time of original data merge, but added in later
gpw4<-read.csv("input_data/merge_terra_indigenaPolygon_id_thin.csv")
for (i in 2:length(gpw4))
{
  colnames(gpw4)[i]<- sub("gpw4","Pop",colnames(gpw4)[i])
  colnames(gpw4)[i]<- sub("ncc4","ntl",colnames(gpw4)[i])
  colnames(gpw4)[i]<-sub("e","",colnames(gpw4)[i])
}
#drop extra columns
gpw4<-gpw4[,!grepl("^d",names(gpw4))]
gpw4<-gpw4[,3:29]
#merge
kfw.SPDF<-merge(kfw.SPDF,gpw4)
#interpolate pop values for missing years within kfw.SPDF, so value for every year from 1982-2010
kfw.SPDF$Pop_90.95<-(kfw.SPDF$Pop_1995-kfw.SPDF$Pop_1990)/5
kfw.SPDF$Pop_1991<-kfw.SPDF$Pop_1990+kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1992<-kfw.SPDF$Pop_1991+kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1993<-kfw.SPDF$Pop_1992+kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1994<-kfw.SPDF$Pop_1993+kfw.SPDF$Pop_90.95

kfw.SPDF$Pop_1989<-kfw.SPDF$Pop_1990-kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1988<-kfw.SPDF$Pop_1989-kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1987<-kfw.SPDF$Pop_1988-kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1986<-kfw.SPDF$Pop_1987-kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1985<-kfw.SPDF$Pop_1986-kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1984<-kfw.SPDF$Pop_1985-kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1983<-kfw.SPDF$Pop_1984-kfw.SPDF$Pop_90.95
kfw.SPDF$Pop_1982<-kfw.SPDF$Pop_1983-kfw.SPDF$Pop_90.95
#1995-2000
kfw.SPDF$Pop_95.2000<-(kfw.SPDF$Pop_2000-kfw.SPDF$Pop_1995)/5
kfw.SPDF$Pop_1996<-kfw.SPDF$Pop_1995+kfw.SPDF$Pop_95.2000
kfw.SPDF$Pop_1997<-kfw.SPDF$Pop_1996+kfw.SPDF$Pop_95.2000
kfw.SPDF$Pop_1998<-kfw.SPDF$Pop_1997+kfw.SPDF$Pop_95.2000
kfw.SPDF$Pop_1999<-kfw.SPDF$Pop_1998+kfw.SPDF$Pop_95.2000
#2000-2005
kfw.SPDF$Pop_2000.05<-(kfw.SPDF$Pop_2005-kfw.SPDF$Pop_2000)/5
kfw.SPDF$Pop_2001<-kfw.SPDF$Pop_2000+kfw.SPDF$Pop_2000.05
kfw.SPDF$Pop_2002<-kfw.SPDF$Pop_2001+kfw.SPDF$Pop_2000.05
kfw.SPDF$Pop_2003<-kfw.SPDF$Pop_2002+kfw.SPDF$Pop_2000.05
kfw.SPDF$Pop_2004<-kfw.SPDF$Pop_2003+kfw.SPDF$Pop_2000.05
#2005-2010
kfw.SPDF$Pop_2005.10<-(kfw.SPDF$Pop_2010-kfw.SPDF$Pop_2005)/5
kfw.SPDF$Pop_2006<-kfw.SPDF$Pop_2005+kfw.SPDF$Pop_2005.10
kfw.SPDF$Pop_2007<-kfw.SPDF$Pop_2006+kfw.SPDF$Pop_2005.10
kfw.SPDF$Pop_2008<-kfw.SPDF$Pop_2007+kfw.SPDF$Pop_2005.10
kfw.SPDF$Pop_2009<-kfw.SPDF$Pop_2008+kfw.SPDF$Pop_2005.10
#drop unused columns
kfw.SPDF<-kfw.SPDF[,-grep("(Pop_90.95)",names(kfw.SPDF))]
kfw.SPDF<-kfw.SPDF[,-grep("(Pop_95.2000)",names(kfw.SPDF))]
kfw.SPDF<-kfw.SPDF[,-grep("(Pop_2000.05)",names(kfw.SPDF))]
kfw.SPDF<-kfw.SPDF[,-grep("(Pop_2005.10)",names(kfw.SPDF))]
#reorder columns chronologically
kfw.SPDF<-kfw.SPDF[,order(names(kfw.SPDF))]

#Continious NDVI - LTDR - MEAN----------------------------------------------------
LTDR_mean <- "input_data/sciclone_extracts/LTDR_merge_year_mean.csv"
LTDR_mean <- read.csv(LTDR_mean)
#Rename columns...
for (i in 2:length(LTDR_mean))
{
  colnames(LTDR_mean)[i] <- sub("NDVI","",colnames(LTDR_mean)[i])
  colnames(LTDR_mean)[i] <- sub("X","MeanL_",colnames(LTDR_mean)[i])
}


#Merge it in
kfw.SPDF <- merge(kfw.SPDF, LTDR_mean, by.x="id", by.y="id")


#Continious NDVI - LTDR - MAX----------------------------------------------------
LTDR_max <- "input_data/sciclone_extracts/LTDR_merge_year_max.csv"
LTDR_max <- read.csv(LTDR_max)
#Rename columns...
for (i in 2:length(LTDR_max))
{
  colnames(LTDR_max)[i] <- sub("NDVI","",colnames(LTDR_max)[i])
  colnames(LTDR_max)[i] <- sub("X","MaxL_",colnames(LTDR_max)[i])
}


#Merge it in
kfw.SPDF <- merge(kfw.SPDF, LTDR_max, by.x="id", by.y="id")

#Continuous NDVI - LTDR - median of the yearly max-----------------------------
#Merge in median NDVI (median of the yearly max by community)
LTDR_median <-read.csv("input_data/sciclone_extracts/medianNDVI_terra_indigenaPolygon_id_thin.csv")
LTDR_median<-LTDR_median[,!names(LTDR_median) %in% "SP_ID"]
LTDR_median[,2:33]<- LTDR_median[,2:33]/10000

#Rename columns...
for (i in 2:length(LTDR_median))
{
  colnames(LTDR_median)[i] <- sub("ltdr_yearly_ndvi_max.","MedL_",colnames(LTDR_median)[i])
  colnames(LTDR_median)[i]<-sub(".median","",colnames(LTDR_median)[i])
}

#Merge it in
kfw.SPDF <- merge(kfw.SPDF, LTDR_median, by.x="id", by.y="id")

#Slope ----------------------------------------------------
SRTM_slope <- "input_data/sciclone_extracts/SRTM_500m_slope.shp"
SRTM_slope <- readShapePoly(SRTM_slope)
SRTM_slope <- SRTM_slope@data
#Keep only the relevant columns
SRTM_slope <- SRTM_slope[c("id","SRTM_500m_")]

#Rename
colnames(SRTM_slope)[2] <- "Slope"
#Merge it in
kfw.SPDF <- merge(kfw.SPDF, SRTM_slope, by.x="id", by.y="id")

#Elevation -----------------------------------------------
SRTM_elev <- "input_data/sciclone_extracts/SRTM_500m.shp"
SRTM_elev <- readShapePoly(SRTM_elev)
SRTM_elev <- SRTM_elev@data
#Keep only the relevant columns
SRTM_elev <- SRTM_elev[c("id","SRTM_500m")]

#Rename
colnames(SRTM_elev)[2] <- "Elevation"
#Merge it in
kfw.SPDF <- merge(kfw.SPDF, SRTM_elev, by.x="id", by.y="id")

#Urban travel time ---------------------------------------
urb_trv <- "input_data/sciclone_extracts/access_50k.shp"
urb_trv <- readShapePoly(urb_trv)
urb_trv <- urb_trv@data
#Keep only the relevant columns
urb_trv <- urb_trv[c("id","access_50k")]

#Rename
colnames(urb_trv)[2] <- "UrbTravTime"
#Merge it in
kfw.SPDF <- merge(kfw.SPDF, urb_trv, by.x="id", by.y="id")

#Air Temperature----------------------------------------------
air_temp <-("input_data/sciclone_extracts/temp_extract_merge.csv")
air_temp <- read.csv(air_temp)

keep <- c("id")
for (i in 2:length(air_temp)) {
  
  if (substr(colnames(air_temp)[i], 1, 4) == "at41") {
    
    year = substr(colnames(air_temp)[i], 6, 9)
    month = substr(colnames(air_temp)[i], 10, 11)
    dt = paste(year,"-",month,sep="")
    colnames(air_temp)[i] <- dt
    
    keep<-append(keep, dt)
  } 
}
air_temp <- air_temp[keep]

air_temp_ts <- melt(air_temp,id="id")
air_temp_ts <- cSplit(air_temp_ts, "variable", "-")
air_temp_ts_mean <- aggregate(value ~ variable_1 + id, air_temp_ts, FUN=mean)
air_temp_ts_max <- aggregate(value ~ variable_1 + id, air_temp_ts, FUN=max)
air_temp_ts_min <- aggregate(value ~ variable_1 + id, air_temp_ts, FUN=min)
air_temp_mean <- reshape(air_temp_ts_mean, idvar=c("id"), direction="wide", timevar="variable_1")
air_temp_max <- reshape(air_temp_ts_max, idvar=c("id"), direction="wide", timevar="variable_1")
air_temp_min <- reshape(air_temp_ts_min, idvar=c("id"), direction="wide", timevar="variable_1")

#Rename vars
for (i in 2:length(air_temp_mean))
{
  colnames(air_temp_mean)[i] <- sub("value.","MeanT_",colnames(air_temp_mean)[i])
  colnames(air_temp_max)[i] <- sub("value.","MaxT_",colnames(air_temp_max)[i])
  colnames(air_temp_min)[i] <- sub("value.","MinT_",colnames(air_temp_min)[i])
}

#ggplot() + geom_point(data=air_temp_ts_mean, aes(x=value, y=variable_1, colour=factor(id))) + scale_fill_manual(values=c("blue","cyan4"))
#Merge it in
kfw.SPDF <- merge(kfw.SPDF, air_temp_mean, by.x="id", by.y="id")
kfw.SPDF <- merge(kfw.SPDF, air_temp_max, by.x="id", by.y="id")
kfw.SPDF <- merge(kfw.SPDF, air_temp_min, by.x="id", by.y="id")


#Precipitation----------------------------------------------
precip <- "input_data/sciclone_extracts/precip_extract_merge.csv"
precip <- read.csv(precip)

keep <- c("id")
for (i in 2:length(precip)) {
  
  if (substr(colnames(precip)[i], 1, 4) == "pc41"){

  year = substr(colnames(precip)[i], 6, 9)
  month = substr(colnames(precip)[i], 10, 11)
  dt = paste(year,"-",month,sep="")
  colnames(precip)[i] <- dt
  
  keep<-append(keep,dt)
  }
}

precip <- precip[keep]

precip_ts <- melt(precip,id="id")
precip_ts <- cSplit(precip_ts, "variable", "-")
precip_ts_mean <- aggregate(value ~ variable_1 + id, precip_ts, FUN=mean)
precip_ts_max <- aggregate(value ~ variable_1 + id, precip_ts, FUN=max)
precip_ts_min <- aggregate(value ~ variable_1 + id, precip_ts, FUN=min)
precip_mean <- reshape(precip_ts_mean, idvar=c("id"), direction="wide", timevar="variable_1")
precip_max <- reshape(precip_ts_max, idvar=c("id"), direction="wide", timevar="variable_1")
precip_min <- reshape(precip_ts_min, idvar=c("id"), direction="wide", timevar="variable_1")

#Rename vars
for (i in 2:length(precip_mean))
{
  colnames(precip_mean)[i] <- sub("value.","MeanP_",colnames(precip_mean)[i])
  colnames(precip_max)[i] <- sub("value.","MaxP_",colnames(precip_max)[i])
  colnames(precip_min)[i] <- sub("value.","MinP_",colnames(precip_min)[i])
}

#ggplot() + geom_point(data=air_temp_ts_mean, aes(x=value, y=variable_1, colour=factor(id))) + scale_fill_manual(values=c("blue","cyan4"))
#Merge it in
kfw.SPDF <- merge(kfw.SPDF, precip_mean, by.x="id", by.y="id")
kfw.SPDF <- merge(kfw.SPDF, precip_max, by.x="id", by.y="id")
kfw.SPDF <- merge(kfw.SPDF, precip_min, by.x="id", by.y="id")

#Distance to Rivers
Riv_dist <- "input_data/sciclone_extracts/rivers_dist_sa.shp"
Riv_dist <- readShapePoly(Riv_dist)
Riv_dist <- Riv_dist@data

Riv_dist <- Riv_dist[c("id","dist")]

#Rename the columns for easier interpretation later..
colnames(Riv_dist)[2] <- "Riv_Dist"
#Merge it in
kfw.SPDF <- merge(kfw.SPDF, Riv_dist, by.x="id", by.y="id")

#Distance to Roads
Road_dist <- "input_data/sciclone_extracts/roads_dist_sa.shp"
Road_dist <- readShapePoly(Road_dist)
Road_dist<- Road_dist@data

Road_dist <- Road_dist[c("id","dist")]

#Rename the columns for easier interpretation later..
colnames(Road_dist)[2] <- "Road_dist"
#Merge it in
kfw.SPDF <- merge(kfw.SPDF, Road_dist, by.x="id", by.y="id")

#KFW Treatment Indicators
KFW_trt <- "input_data/KFW_treatment.csv"
KFW_trt <- read.csv(KFW_trt)

#Merge in the KFW data
kfw.SPDF <- merge(kfw.SPDF, KFW_trt, by.x="id", by.y="id")

#Redefine the size as a numeric.
kfw.SPDF@data["terrai_are"] <- lapply(kfw.SPDF@data["terrai_are"], function(x) as.numeric(gsub("Ha","",x)))

#Merge in the community enforcement data
KFW_enf <- "input_data/EnforcementData_FUNAIFinalReport.csv"
KFW_enf <- read.csv(KFW_enf)

#Merge in the KFW enf data
kfw.SPDF <- merge(kfw.SPDF, KFW_enf, by.x="id", by.y="id")

#Merge in the covariates to predict high-pressure communities, collected by Ash
KFW_covars <- "input_data/HighPressureCommCovars__Abbrev_Ash.csv"
KFW_covars <- read.csv(KFW_covars)

kfw.SPDF <- merge (kfw.SPDF, KFW_covars, by.x="id", by.y="id")

writePolyShape(kfw.SPDF,"processed_data/kfw_analysis_inputs.shp")

#kfw.SPDF<-readShapePoly("processed_data/kfw_analysis_inputs.shp")
#kfw.SPDF<-kfw.SPDF[,1:341]
