#' Get a handful of demographic variables from the US Census Bureau as a data.frame.
#' 
#' The data comes from the American Community Survey (ACS). The geographic unit is 
#' Zip Code Tabulated Areas (ZCTAs). The variables are: total population, percent White 
#' not Hispanic, Percent Black or African American not Hispanic, percent Asian not Hispanic,
#' percent Hispanic all races, per-capita income, median rent and median age.
#' @param endyear The end year for the survey
#' @param span The span of the survey
#' @references The choroplethr guide to Census data: http://cran.r-project.org/web/packages/choroplethr/vignettes/e-mapping-us-census-data.html
#' @references A list of all ACS Surveys: http://factfinder.census.gov/faces/affhelp/jsf/pages/metadata.xhtml?lang=en&type=survey&id=survey.en.ACS_ACS
#' @importFrom acs geo.make acs.fetch geography estimate
#' @importFrom choroplethr get_acs_data
#' @export
get_zip_demographics = function(endyear=2013, span=5)
{
  zip_geo   = acs::geo.make(zip.code = "*")
  race.data = acs::acs.fetch(geography    = zip_geo, 
                             table.number = "B03002", 
                             col.names    = "pretty", 
                             endyear      = endyear, 
                             span         = span)
  
  # convert to a data.frame 
  df_race = data.frame(region                   = as.character(acs::geography(race.data)$zipcodetabulationarea), 
                       total_population         = as.numeric(acs::estimate(race.data[,1])),
                       white_alone_not_hispanic = as.numeric(acs::estimate(race.data[,3])),
                       black_alone_not_hispanic = as.numeric(acs::estimate(race.data[,4])),
                       asian_alone_not_hispanic = as.numeric(acs::estimate(race.data[,6])),
                       hispanic_all_races       = as.numeric(acs::estimate(race.data[,12])))
  
  df_race$region = as.character(df_race$region) # no idea why, but it's a factor before this line
  
  df_race$percent_white    = round(df_race$white_alone_not_hispanic / df_race$total_population * 100)
  df_race$percent_black    = round(df_race$black_alone_not_hispanic / df_race$total_population * 100)
  df_race$percent_asian    = round(df_race$asian_alone_not_hispanic / df_race$total_population * 100)
  df_race$percent_hispanic = round(df_race$hispanic_all_races       / df_race$total_population * 100)
  
  df_race = df_race[, c("region", "total_population", "percent_white", "percent_black", "percent_asian", "percent_hispanic")]
  
  # per capita income 
  df_income = choroplethr::get_acs_data("B19301", "zip", endyear=2013, span=5)[[1]]  
  colnames(df_income)[[2]] = "per_capita_income"
  
  # median rent
  df_rent = get_acs_data("B25058", "zip", endyear=2013, span=5)[[1]]  
  colnames(df_rent)[[2]] = "median_rent"
  
  # median age
  # can't do get_acs_data here because there seems to be a bug with how column_idx is treated right now
  #df_age = get_acs_data("B01002", "zip", endyear=2013, span=5, column_idx=1)[[1]]  
  age    = acs::acs.fetch(geography=zip_geo, table.number = "B01002", col.names = "pretty", endyear = 2013, span = 5)
  df_age = choroplethr:::convert_acs_obj_to_df("zip", age, 1) 
  colnames(df_age)[[2]] = "median_age"
  
  df_demographics = merge(df_race        , df_income, all.x=TRUE)
  df_demographics = merge(df_demographics, df_rent  , all.x=TRUE)  
  df_demographics = merge(df_demographics, df_age   , all.x=TRUE)
  
  # remove the regions (such as zips in Puerto Rico) that are not on my map.
  data(zip.regions, package="choroplethrZip", envir=environment())
  df_demograhpics = df_demographics[df_demographics$region %in% zip.regions$region, ]
  
  df_demographics
}