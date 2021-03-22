# Created on 2020-05-26 by Anna Ivanova
# Based on the code by Rachel Ryskin
# edited on 2021-02-28 by Zawad Chowdhury

rm(list=ls())
library(tidyverse)
library(stringr)
library(stringi)

# READ DATA
filenames=c('../results_raw/Batch_4332828_batch_results.csv',
             '../results_raw/Batch_4368386_batch_results.csv')

data <- lapply(filenames, read.csv)
data = do.call("rbind", data)

num.trials = 54  # maximum number of trials per participant

# only keep WorkerId and cols that Start with Answer or Input
data = data %>% select(starts_with('Input'),starts_with('Answer'),
                       starts_with('WorkerId'),starts_with('WorkTimeInSeconds'),
                       starts_with('HITId')) 

# checksdf = data %>% select(starts_with('WorkerId'))

checksdf = data %>% select(c('WorkerId', 'Answer.English', 'Answer.country',
                             'Answer.proficiency1', 'Answer.proficiency2',
                             'WorkTimeInSeconds', 'Answer.answer', 'HITId'))

# gather (specify the list of columns you need)
data = data %>% gather(key='variable',value="value",
                       -WorkerId,-Input.list,-Answer.country,
                       -Answer.English,-Answer.answer, -Answer.proficiency1,
                       -Answer.proficiency2, -WorkTimeInSeconds,
                       -Answer.profcheck1, -Answer.profcheck2, -HITId)

# separate
data = data %>% separate(variable, into=c('Type','TrialNum'),sep='__',convert=TRUE) 

# spread
data = data %>% spread(key = Type, value = value)

# exclude bad workers (note: currently done manually)
# data = data %>%
#   filter(!(WorkerId %in% c('AT8S19U5993HR', 'A2R1A479K07ME5')))                   # bad responses

## Summarize ratings data 
data$Answer.Rating <- as.numeric(data$Answer.Rating)

## replace plausible-0 with plausible, for easy filtering
data$Input.code <- gsub('plausible-0', 'plausible', data$Input.code)
data$Input.code <- gsub('plausible-1', 'plausible', data$Input.code)

checksdf$filler.left <- data[data[, "Input.code"]=="filler_filler_2_NO_QUESTION",
                      "Answer.Rating"]
checksdf$filler.right <- data[data[, "Input.code"]=="filler_filler_1_NO_QUESTION",
                            "Answer.Rating"]

# separate the Input code into categories
data = data %>% 
  separate(Input.code,into=c('TrialType','cond','Item','xx1','xx2'),sep='_') %>%
  separate(cond, into=c('Voice', 'Plausibility', 'xx3'), sep='-')

# info we don't need
data$xx3 = NULL
data$xx1 = NULL
data$xx2 = NULL

# ANALYSES

## Look at data by participant (TODO: fix avg rating for plaus and implaus)

data = data %>% 
  group_by(WorkerId) %>%
  mutate(
    na.pct = mean(is.na(Answer.Rating)),
    n = length(Answer.Rating),
    ) %>%
  ungroup()

# To look at only AI output
data = data %>% filter(TrialType == "AI")

data = data %>% 
  group_by(WorkerId, Plausibility) %>%
  mutate(
    avrating = mean(Answer.Rating, na.rm=TRUE)
    ) %>%
  ungroup()


data_summ = data %>% group_by(WorkerId, Plausibility) %>%
  summarize(
    na.pct = mean(na.pct),
    n = mean(n),
    avrating = mean(avrating),
    ) %>%
  spread(key=Plausibility, value=avrating)


data_summ = merge(data_summ, checksdf, by="WorkerId")

data_summ$diff = data_summ$plausible - data_summ$implausible

data_summ[!is.na(data_summ$diff) & data_summ$diff < 2, "Reject"] = 
  "Improper ratings of implausible and plausible sentences."

data_summ[!is.na(data_summ$filler.left) & data_summ$filler.left != 7, "Reject"] =
  "Missed attention check."

data_summ[!is.na(data_summ$filler.right) & data_summ$filler.right != 1, "Reject"] =
  "Missed attention check."

data_summ[data_summ$na.pct > 0.3, "Reject"] = "Too many questions not answered."

rejectdf = data_summ %>% select(c('HITId', 'Reject'))
rejectdf[is.na(rejectdf$Reject), "Accept"] = "x"


## save a summary of individual subjects' performance
write_csv(data_summ,"data_summ_by_worker_AIonly.csv")

