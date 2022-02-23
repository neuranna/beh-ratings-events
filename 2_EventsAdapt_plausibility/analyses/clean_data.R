# Created on 2020-05-26 by Anna Ivanova
# Based on the code by Rachel Ryskin
# edited on 2021-02-28 by Zawad Chowdhury 
# edited on 2022-02-18 by Anna Ivanova (refactoring)

# SETUP
rm(list=ls())
library(tidyverse)
library(stringr)
library(stringi)

# decide whether to do minimal filtering based on plausibility ratings themselves
# (should be very obvious for AI items)
AI_plaus_filter = TRUE

# READ DATA
filenames=c('../results_raw/Batch_4430335_batch_results_raw.csv',
            '../results_raw/Batch_4332828_batch_results_raw.csv',
            '../results_raw/Batch_4368386_batch_results_raw.csv')

data <- lapply(filenames, read.csv)
data = do.call("rbind", data)

num.trials = 54  # maximum number of trials per participant

# only keep relevant columns
data = data %>% select(starts_with('Input'),starts_with('Answer'),
                       starts_with('WorkerId'),starts_with('WorkTimeInSeconds'),
                       starts_with('HITId'), starts_with('AssignmentStatus'),
                       starts_with('AssignmentId'))

# checksdf = data %>% select(c('WorkerId', 'Answer.English', 'Answer.country',
#                              'Answer.proficiency1', 'Answer.proficiency2',
#                              'WorkTimeInSeconds', 'Answer.answer', 'HITId', 
#                              'AssignmentStatus', 'AssignmentId'))

# CLEAN
data = data %>% gather(key='variable',value="value",
                       -WorkerId,-Input.list,-Answer.country,
                       -Answer.English,-Answer.answer, -Answer.proficiency1,
                       -Answer.proficiency2, -WorkTimeInSeconds, -HITId, 
                       -AssignmentStatus, -AssignmentId)

data = data %>% 
  separate(variable, into=c('Type','TrialNum'),sep='__',convert=TRUE) %>% 
  spread(key = Type, value = value)

data$Answer.Rating <- as.numeric(data$Answer.Rating)

## replace plausible-0 with plausible, for easy filtering
data$Input.code <- gsub('plausible-0', 'plausible', data$Input.code)
data$Input.code <- gsub('plausible-1', 'plausible', data$Input.code)

# checksdf$filler.left <- data[data[, "Input.code"]=="filler_filler_2_NO_QUESTION",
#                       "Answer.Rating"]
# checksdf$filler.right <- data[data[, "Input.code"]=="filler_filler_1_NO_QUESTION",
#                             "Answer.Rating"]

# separate the Input code into categories
data = data %>% 
  separate(Input.code,into=c('TrialType','cond','Item','xx1','xx2'),sep='_') %>%
  separate(cond, into=c('Voice', 'Plausibility', 'xx3'), sep='-') %>%
  select(-xx1, -xx2, -xx3)


# ANALYSES

## Look at data by participant 
data.worker = data %>% 
  group_by(WorkerId, HITId) %>%
  summarize(num_questions = length(Answer.Rating),
            num_missed = sum(is.na(Answer.Rating)),
            ratio_missed = num_missed/num_questions,
            native_english = all(Answer.English=='yes'),
            country_usa = all(Answer.country=='USA'),
            filler1 = Answer.Rating[TrialType=="filler" & Item=="1"],
            filler2 = Answer.Rating[TrialType=="filler" & Item=="2"],
            fillers_correct = (filler1==1 & filler2==7))

# exclude
data.worker.clean = data.worker %>%
  filter(native_english, country_usa,
         ratio_missed<0.2, fillers_correct)

# filter on average plausibility diff for AI sentences
if (AI_plaus_filter) {
  data.summ.AI = data %>%
    filter(TrialType=="AI") %>%
    group_by(WorkerId, HITId, Plausibility) %>%
    summarize(avg_rating = mean(Answer.Rating, na.rm=TRUE)) %>%
    ungroup() %>%
    group_by(WorkerId, HITId) %>%
    summarize(AI_rating_diff = avg_rating[Plausibility=="plausible"]-avg_rating[Plausibility=="implausible"]) 
  data.worker.clean = merge(data.worker.clean, data.summ.AI)
  
  AI_diff_threshold=1
  data.worker.clean = data.worker.clean %>% 
    filter(AI_rating_diff>=AI_diff_threshold)
}

# add info about manual proficiency checks (sentence completion)
data.worker.profcheck = read.csv("worker_proficiency_check.csv") 

if (any(sapply(data.worker.clean$WorkerId, function(x) {!(x %in% data.worker.profcheck$WorkerId)}))) {
  extraIDs = data.worker.clean %>% filter(!(WorkerId %in% data.worker.profcheck$WorkerId)) %>%
    select(WorkerId) %>% distinct()
  warning('Not all workers have proficiency check info. Info missing for:\n') 
  warning(paste(extraIDs$WorkerId, '\n'))
}


data.worker.clean = merge(data.worker.clean,
                    data.worker.profcheck %>% select(WorkerId, HITId, proficiency_check_passed) %>%
                      distinct())


## WORKER STATS
num_workers_all = length(unique(data$WorkerId))
num_workers_clean = length(unique(data.worker.clean$WorkerId))

num_hits_per_worker = data %>% 
  group_by(WorkerId) %>%
  summarize(numHits = length(unique(HITId))) %>%
  ungroup() %>%
  summarize(avg = mean(numHits),
            min = min(numHits),
            max = max(numHits))

num_sents_per_worker = data %>%
  group_by(WorkerId) %>%
  summarize(numSents=length(Item)) %>%
  ungroup() %>%
  summarize(avg = mean(numSents),
            min = min(numSents),
            max = max(numSents))

time_per_worker = data %>% 
  select(WorkerId, HITId, WorkTimeInSeconds) %>%
  ungroup() %>% distinct() %>%
  summarize(TimeInMin = mean(WorkTimeInSeconds))
 

# save worker data
write.csv(data.worker, "data_worker_all.csv")
write.csv(data.worker.clean, "data_worker_clean.csv")


# filter big data df based on worker info and save
data$Item = as.numeric(data$Item)
data.clean = data %>% 
  filter(WorkerId %in% data.worker.clean$WorkerId) %>%
  filter(TrialType!='filler') %>%
  select(WorkerId, HITId, TrialNum, Answer.Rating, TrialType, Voice, Plausibility, Item, Input.trial) %>%
  arrange(WorkerId, HITId, Item)

write.csv(data.clean, "longform_data.csv", row.names=FALSE)
