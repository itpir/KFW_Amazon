#-------------------------------------------------
#-------------------------------------------------
#Panel Models - KFW
#Testing in Cross Section the impact of being treated BEFORE March, 2001
#On the Mean Level of NDVI, measured as the yearly mean NDVI value (LTDR)
#-------------------------------------------------
#-------------------------------------------------
library(devtools)
devtools::install_github("itpir/SAT@master")
library(SAT)
library(stargazer)
library(lmtest)
library(multiwayvcov)
loadLibs()
#-------------------------------------------------
#-------------------------------------------------
#Load in Processed Data - produced from script KFW_dataMerge.r
#-------------------------------------------------
#-------------------------------------------------

shpfile = "processed_data/kfw_analysis_inputs.shp"
dta_Shp = readShapePoly(shpfile)

#-------------------------------------------------
#-------------------------------------------------
#Pre-processing to create cross-sectional variable summaries
#-------------------------------------------------
#-------------------------------------------------
#Calculate NDVI Trends
dta_Shp$pre_trend_NDVI_mean <- timeRangeTrend(dta_Shp,"MeanL_[0-9][0-9][0-9][0-9]",1982,1995,"SP_ID")
dta_Shp$pre_trend_NDVI_max <- timeRangeTrend(dta_Shp,"MaxL_[0-9][0-9][0-9][0-9]",1982,1995,"SP_ID")
dta_Shp$NDVIslope_95_10 <- timeRangeTrend(dta_Shp,"MaxL_[0-9][0-9][0-9][0-9]",1995,2010,"SP_ID")
dta_Shp@data["NDVIslopeChange_95_10"] <- dta_Shp$MeanL_2010 - dta_Shp$MeanL_1995

#NDVI Trends for 1995-2001
dta_Shp$post_trend_NDVI_95_01 <- timeRangeTrend(dta_Shp,"MeanL_[0-9][0-9][0-9][0-9]",1995,2001,"SP_ID")
dta_Shp@data["NDVIslopeChange_95_01"] <- dta_Shp$MeanL_2001 - dta_Shp$MeanL_1995
#NDVI Trends for 2001-2010
dta_Shp$post_trend_NDVI_01_10 <- timeRangeTrend(dta_Shp,"MeanL_[0-9][0-9][0-9][0-9]",2001,2010,"SP_ID")
dta_Shp@data["NDVIslopeChange_01_10"] <- dta_Shp$MeanL_2010 - dta_Shp$MeanL_2001
#dta_Shp@data["NDVIslopeChange_01_10"] <- dta_Shp@data["post_trend_NDVI_01_10"] - dta_Shp@data["pre_trend_NDVI_max"]

#Calculate Temp and Precip Pre and Post Trends
dta_Shp$pre_trend_temp_mean <- timeRangeTrend(dta_Shp,"MeanT_[0-9][0-9][0-9][0-9]",1982,1995,"SP_ID")
dta_Shp$pre_trend_temp_max <- timeRangeTrend(dta_Shp,"MaxT_[0-9][0-9][0-9][0-9]",1982,1995,"SP_ID")
dta_Shp$pre_trend_temp_min <- timeRangeTrend(dta_Shp,"MinT_[0-9][0-9][0-9][0-9]",1982,1995,"SP_ID")

dta_Shp$post_trend_temp_mean <- timeRangeTrend(dta_Shp,"MeanT_[0-9][0-9][0-9][0-9]",1995,2010,"SP_ID")
dta_Shp$post_trend_temp_max <- timeRangeTrend(dta_Shp,"MaxT_[0-9][0-9][0-9][0-9]",1995,2010,"SP_ID")
dta_Shp$post_trend_temp_min <- timeRangeTrend(dta_Shp,"MinT_[0-9][0-9][0-9][0-9]",1995,2010,"SP_ID")
dta_Shp$post_trend_temp_95_01 <- timeRangeTrend(dta_Shp,"MeanT_[0-9][0-9][0-9][0-9]",1995,2001,"SP_ID")
dta_Shp$post_trend_temp_01_10 <- timeRangeTrend(dta_Shp,"MeanT_[0-9][0-9][0-9][0-9]",2001,2010,"SP_ID")

dta_Shp$pre_trend_precip_mean <- timeRangeTrend(dta_Shp,"MeanP_[0-9][0-9][0-9][0-9]",1982,1995,"SP_ID")
dta_Shp$pre_trend_precip_max <- timeRangeTrend(dta_Shp,"MaxP_[0-9][0-9][0-9][0-9]",1982,1995,"SP_ID")
dta_Shp$pre_trend_precip_min <- timeRangeTrend(dta_Shp,"MinP_[0-9][0-9][0-9][0-9]",1982,1995,"SP_ID")

dta_Shp$post_trend_precip_mean <- timeRangeTrend(dta_Shp,"MeanP_[0-9][0-9][0-9][0-9]",1995,2010,"SP_ID")
dta_Shp$post_trend_precip_max <- timeRangeTrend(dta_Shp,"MaxP_[0-9][0-9][0-9][0-9]",1995,2010,"SP_ID")
dta_Shp$post_trend_precip_min <- timeRangeTrend(dta_Shp,"MinP_[0-9][0-9][0-9][0-9]",1995,2010,"SP_ID")
dta_Shp$post_trend_precip_95_01 <- timeRangeTrend(dta_Shp,"MeanP_[0-9][0-9][0-9][0-9]",1995,2001,"SP_ID")
dta_Shp$post_trend_precip_01_10 <- timeRangeTrend(dta_Shp,"MeanP_[0-9][0-9][0-9][0-9]",2001,2010,"SP_ID")


#-------------------------------------------------
#-------------------------------------------------
#Define the Treatment Variable and Population
#-------------------------------------------------
#-------------------------------------------------
#Make a binary to test treatment..
dta_Shp@data["TrtBin"] <- 0
dta_Shp@data$TrtBin[dta_Shp@data$demend_y <= 2001] <- 1
dta_Shp@data$TrtBin[(dta_Shp@data$demend_m > 4) & (dta_Shp@data$demend_y==2001)] <- 0

#Remove units that did not ever receive any treatment (within-sample test)
dta_Shp@data$NA_check <- 0
dta_Shp@data$NA_check[is.na(dta_Shp@data$demend_y)] <- 1
int_Shp <- dta_Shp[dta_Shp@data$NA_check != 1,]
dta_Shp <- int_Shp


#-------------------------------------------------
#-------------------------------------------------
#Define and run the first-stage of the PSM, calculating propensity scores
#-------------------------------------------------
#-------------------------------------------------
psmModel <-  "TrtBin ~ terrai_are + Pop_1990 + MeanT_1995 + pre_trend_temp_mean + pre_trend_temp_min + 
pre_trend_temp_max + MeanP_1995 + pre_trend_precip_min + 
pre_trend_NDVI_mean + pre_trend_NDVI_max + Slope + Elevation + MaxL_1995 + Riv_Dist + Road_dist +
pre_trend_precip_mean + pre_trend_precip_max" 
#MeanL_1995 + 


psmRes <- SAT::SpatialCausalPSM(dta_Shp,mtd="logit",psmModel,drop="support",visual=FALSE)


#-------------------------------------------------
#-------------------------------------------------
#Based on the Propensity Score Matches, pair comprable treatment and control units.
#-------------------------------------------------
#-------------------------------------------------
drop_set<- c(drop_unmatched=TRUE,drop_method="None",drop_thresh=0.25)
psm_Pairs <- SAT(dta = psmRes$data, mtd = "fastNN",constraints=c(groups="UF"),psm_eq = psmModel, ids = "id", drop_opts = drop_set, visual="TRUE", TrtBinColName="TrtBin")
#c(groups=c("UF"),distance=NULL)
trttable <- table (psm_Pairs@data$TrtBin)
View(trttable)


#-------------------------------------------------
#-------------------------------------------------
#Convert from a wide-form dataset for the Cross-sectional 
#to a long-form dataset for the panel model.
#-------------------------------------------------
#-------------------------------------------------
#Clean up data entry
#psm_Pairs$enforce_st[psm_Pairs$enforce_st == "1998-1999"] <- NA
#psm_Pairs$enforce_st <- as.numeric(paste(psm_Pairs$enforce_st))

varList = c("MeanL_","MaxL_")
psm_Long <- BuildTimeSeries(dta=psm_Pairs,idField="reu_id",varList_pre=varList,1982,2010,colYears=c("demend_y","apprend_y","regend_y"),interpYears=c("Slope","Road_dist","Riv_Dist","UF","Elevation","terrai_are","Pop_","MeanT_","MeanP_","MaxT_","MaxP_","MinP_","MinT_","TrtBin"))
psm_Long$Year <- as.numeric(psm_Long$Year)

write.csv(psm_Long,file="/Users/rbtrichler/Documents/AidData/KFW Brazil Eval/KFW/KFW_Comm/psm_Long.csv")

#create dummy for being in UF in arc of deforestation (para, mato grosso, rondonia, maranhao, tocantins)
psm_Long$arc<-NA
psm_Long$arc[which(psm_Long$UF=="PA")] <-1
psm_Long$arc[which(psm_Long$UF!="PA")]<-0

pModelMax_A <- "MaxL_ ~ TrtMnt_demend_y + factor(reu_id) "
pModelMax_B <- "MaxL_ ~ TrtMnt_demend_y + MeanT_ + MeanP_ + Pop_ + MaxT_ + MaxP_ + MinT_ + MinP_  + factor(reu_id) "
pModelMax_C <- "MaxL_ ~ TrtMnt_demend_y + MeanT_ + MeanP_ + Pop_ + MaxT_ + MaxP_ + MinT_ + MinP_  + Year + factor(reu_id)"
pModelMax_D <- "MaxL_ ~ TrtMnt_demend_y + MeanT_ + MeanP_ + Pop_ + MaxT_ + MaxP_ + MinT_ + MinP_  + factor(reu_id) + factor(Year)"
pModelMax_E <- "MaxL_ ~ TrtMnt_demend_y + MeanT_ + MeanP_ + Pop_ + MaxT_ + MaxP_ + MinT_ + MinP_  + TrtMnt_demend_y*arc + factor(reu_id) + factor(Year)"

pModelMax_A_fit <- Stage2PSM(pModelMax_A ,psm_Long,type="cmreg", table_out=TRUE, opts=c("reu_id","Year"))
pModelMax_B_fit <- Stage2PSM(pModelMax_B ,psm_Long,type="cmreg", table_out=TRUE, opts=c("reu_id","Year"))
pModelMax_C_fit <- Stage2PSM(pModelMax_C ,psm_Long,type="cmreg", table_out=TRUE, opts=c("reu_id","Year"))
pModelMax_D_fit <- Stage2PSM(pModelMax_D ,psm_Long,type="cmreg", table_out=TRUE, opts=c("reu_id","Year"))
pModelMax_E_fit <- Stage2PSM(pModelMax_E ,psm_Long,type="cmreg", table_out=TRUE, opts=c("reu_id","Year"))


#------------------------------------------------------------------------
#------------------------------------------------------------------------
View(psm_Long$MaxL)
temp_TS_median <- fivenum(psm_Long$MaxL[1041:1120])[3]
high_pressure_regions_1995 <- ifelse(psm_Long$MaxL[1041:1120] > temp_TS_median, 1, 0)


high_pressure_regions <- ifelse(psm_Long$reu_id == 118 | psm_Long$reu_id == 142 | 
                                  psm_Long$reu_id == 105 | psm_Long$reu_id == 148 | 
                                  psm_Long$reu_id == 154 | psm_Long$reu_id == 159 | 
                                  psm_Long$reu_id == 160 | psm_Long$reu_id == 161 | 
                                  psm_Long$reu_id == 162 | psm_Long$reu_id == 163 | 
                                  psm_Long$reu_id == 146 | psm_Long$reu_id == 168 | 
                                  psm_Long$reu_id == 151 | psm_Long$reu_id == 157 | 
                                  psm_Long$reu_id == 170 | psm_Long$reu_id == 174 | 
                                  psm_Long$reu_id == 115 | psm_Long$reu_id == 80 | 
                                  psm_Long$reu_id == 147 | psm_Long$reu_id == 74 | 
                                  psm_Long$reu_id == 88 | psm_Long$reu_id == 155 | 
                                  psm_Long$reu_id == 100 | psm_Long$reu_id == 123 | 
                                  psm_Long$reu_id == 172 | psm_Long$reu_id == 133 | 
                                  psm_Long$reu_id == 85 | psm_Long$reu_id == 89 | 
                                  psm_Long$reu_id == 171 | psm_Long$reu_id == 86 | 
                                  psm_Long$reu_id == 91 | psm_Long$reu_id == 175 | 
                                  psm_Long$reu_id == 130 | psm_Long$reu_id == 113 | 
                                  psm_Long$reu_id == 109 | psm_Long$reu_id == 103 | 
                                  psm_Long$reu_id == 134 | psm_Long$reu_id == 179 | 
                                  psm_Long$reu_id == 94 | psm_Long$reu_id == 95, 1, 0)

high_pressure_regions_int <- (high_pressure_regions * psm_Long$TrtMnt_demend_y)

pModelMax_HP <- "MaxL_ ~ TrtMnt_demend_y + MeanT_ + MeanP_ + Pop_ + MaxT_ + MaxP_ + MinT_ + MinP_  + factor(reu_id) + Year + high_pressure_regions + high_pressure_regions_int"
pModelMax_HP_fit <- Stage2PSM(pModelMax_C ,psm_Long,type="cmreg", table_out=TRUE, opts=c("reu_id","Year"))

#temp_HPR <- ifelse(psm_Long$Year <= 1995 & high_pressure_regions == 1, 1, 0)

stargazer(pModelMax_A_fit $cmreg,pModelMax_B_fit $cmreg,pModelMax_C_fit $cmreg,type="html",align=TRUE,keep=c("TrtMnt","MeanT_","MeanP_","Pop_","MaxT_","MaxP_","MinT_","MinP_","Year"),
          covariate.labels=c("TrtMnt_regend_y","MeanT","MeanP","Pop","MaxT","MaxP","MinT","MinP","Year"),
          omit.stat=c("f","ser"),
          title="Regression Results",
          dep.var.labels=c("Max NDVI")
)

##Workspace

#pre-trend NDVI scatter plot
plot(dta_Shp@data$demend_y, dta_Shp@data$pre_trend_NDVI_max, 
     xlab="Community Demarcation Year",ylab="NDVI Max Pre Trend")
plot(psm_Pairs@data$demend_y, psm_Pairs@data$pre_trend_NDVI_max)

# time series graph with year effects stripped out

reg=lm(MaxL_ ~ factor(Year), data=psm_Long)
psm_Long$resid <- residuals(reg)
plot(psm_Long$resid)

ViewTimeSeries(dta=dta_Shp,IDfield="reu_id",TrtField="TrtBin",idPre="MaxL_[0-9][0-9][0-9][0-9]")
psm_Long2 <- psm_Long

psm_Long2 <- psm_Long[c("Year","resid","reu_id","TrtBin")]

ggplot(data = psm_Long2, aes(x=Year, y=resid, group=reu_id,colour=factor(TrtBin))) + 
  #geom_point(size=.5) +
  geom_line(size=.5, linetype=2) +
  stat_summary(fun.y=mean,aes(x=Year, y=resid, group=TrtBin,colour=factor(TrtBin)),data=psm_Long2,geom='line',size=1.5)+
  theme(axis.text.x=element_text(angle=90,hjust=1))


stat_summary(fun.y=mean,aes(x=Year, y=resid, group="reu_id",colour=factor(TrtBin)),data=psm_Long2,geom='line',size=1.5)+
  
ggplot(data = psm_Long2, aes(x=Year, y=resid, group="reu_id",colour=factor(TrtBin))) + 
  
  stat_summary(fun.y=mean,aes(x=Year, y=resid, group="reu_id",colour=factor(TrtBin)),data=psm_Long2,geom='line',size=1.5)+
  theme(axis.text.x=element_text(angle=90,hjust=1))

