# Static Gear Reports


## Applications
Following iVMS and logbook cleaning/merging, these files allow the user to visualise, quantify, and export (PDF) data concerning the spatial distribution and landings data of static gear fishing. 


By defining a period of time and static gear fishery (currently crab/lobster or whelk), a PDF report will be created containing spatial plots, temporal trends, and general information on the selected fishery and time period.


Users can also configure the report generator to produce public-facing reports that don't include any spatial figures.
<br />
## Prerequisites
- R 4.2 or higher
<br />


# Using the iVMS and Logbook Cleaner



## Step 1: Data Structure and Formatting
1. Make sure you have _tinytex_ installed. If not installed already, use the following code in R to install it to your device.

tinytex::install_tinytex()


2. Ensure that you have followed the intructions for the _iVMS and Logbook Cleaner_, and that all output files have been created:
- u10log_cleaned.csv
- O10log_cleaned.csv
- combinedlog_O10_U10m.csv
- ivms_cleaned.csv
- Join5.csv
- Join10s_4.csv
- Join10m_5.csv

3. Ensure that all 'Join' datasets have the following columns (these should be made by default with _iVMS and Logbook Cleaner_):
- uniqueID
- Vessel.Name
- Departure.Date
- LE_KG_CRE
- LE_KG_LBE
- LE_KG_WHE
- Pot_No_CRE
- Pot_No_LBE
- Pot_No_WHE
- SI_Month
- LE_YEAR
- VE_REF
- SI_DATE
- SI_LONG
- SI_LATI

4. In addition to the iVMS and logbook data, this code requires an additional **reference** data file that contains previous fishing records to compare against (currently set to 2010-2015). This should contain the following columns:
- Date
- wp_hauled _(whelk pots hauled)_
- lp_hauled _(crab/lobster pots hauled)_
- bu_retained _(whelk retained in kg)_
- hg_retained _(lobster retained in kg)_
- cp_retained _(crab retained in kg)_
<br />

## Step 2: Configuring the Report Generator
