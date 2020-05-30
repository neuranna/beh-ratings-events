rm(list=ls())
library(tidyverse)
library(stringr)
library(stringi)

# CHANGE THE PATH TO FOLDER WHERE ALL THE TURK OUTPUTS ARE
#filename='Batch_4055141_batch_results.csv'
filename='Batch_4057413_batch_results.csv'

maxna = .1 # maximum permitted proportion of NA responses per rating question
#mincorrect = .75 # minimum permitted proportion of correct responses to comprehension questions
num.trials = 42  # maximum number of trials per participant

#data = read_csv(file.path(data_path, filename)) %>%
data = read_csv(filename) %>%
  mutate(batch.name = filename)

# only keep WorkerId and cols that Start with Answer or Input
data = data %>% select(starts_with('Input'),starts_with('Answer'),starts_with('WorkerId')) 

# gather (the list of columns may need to be changed depending on what questions you asked)
data = data %>% gather(key='variable',value="value",
                       -WorkerId,-Input.list,-Answer.country,
                       -Answer.English,-Answer.answer
                       )

# separate
data = data %>% separate(variable, into=c('Type','TrialNum'),sep='__',convert=TRUE) 

# spread
data = data %>% spread(key = Type, value = value)

# exclude bad workers
data = data %>%
  filter(!(WorkerId %in% c('AT8S19U5993HR', 'A2R1A479K07ME5')))

## Ways to summarize ratings data if that is your DV

data$Answer.Rating <- as.numeric(data$Answer.Rating)

data = data %>% 
  separate(Input.code,into=c('TrialType','Plausibility','Item','xx1','xx2'),sep='_')
data$TrialType = NULL
data$xx1 = NULL
data$xx2 = NULL

## SAVE A LONGFORM VERSION OF YOUR DATA
write_csv(data,"longform_data.csv")

#%>% 
#  mutate(
#  Correct = correct.answer == Answer.YNQ)
#warning here is because there end up being NAs in the lengthCOnd column for the filler trials

z_score = function(xs) {
  (xs - mean(xs)) / sd(xs)
}

## Add participant correct and na, z score ratings
data_accuracy = data %>% 
  group_by(WorkerId) %>%
  mutate(
    na.pct = mean(is.na(Answer.Rating)),
    correct.pct = mean(Correct,na.rm=TRUE),
    n = length(Answer.Rating)) %>%
  ungroup()

data_summ = data %>% 
  group_by(WorkerId) %>%
  summarize(
    na.pct = mean(is.na(Answer.Rating)),
    correct.pct = mean(Correct,na.rm=TRUE),
    n = length(Answer.Rating))

## save a summary of individual subjects' performance
#write_csv(data_summ,"/Users/rachelryskin/Dropbox (MIT)/psycholinguistics_lab/my_files/turk_expt_in_class/example_data_summ.csv")


#filter for US, English, na, and correct and duplicate, then get z-scores
data.good = data_accuracy %>%
  filter(na.pct <= maxna &
           correct.pct >= mincorrect &
           Answer.English == "yes" &
           Answer.country == "USA" &
           n <= num.trials) %>%
  filter(!is.na(Answer.Rating)) %>% 
  group_by(WorkerId) %>% 
  mutate(
    participant.z = z_score(as.numeric(Answer.Rating)))%>% 
  ungroup()

data.good.summary = data.good %>% 
  filter(trialType == 'particle-length') %>% 
  group_by(shiftCond,lengthCond) %>% 
  summarize(
    m = mean(participant.z),
    stdev= sd(participant.z),
    se = stdev/sqrt(n()),
    upper= m+se*1.96,
    lower=m-se*1.96,
    m.r = mean(Answer.Rating),
    stdev.r= sd(Answer.Rating),
    se.r = stdev.r/sqrt(n()),
    upper.r= m.r+se.r*1.96,
    lower.r=m.r-se.r*1.96
  )
  
# graphs of raw ratings and z-scores by condition 
p1 = ggplot(data=data.good.summary)+
  geom_bar(aes(x=shiftCond,y=m),stat='identity')+
  geom_errorbar(aes(x=shiftCond,ymin=lower,ymax=upper),width = .2)+
  facet_wrap(~lengthCond)+
  ylab('average z-scores')

p1

p2 = ggplot(data=data.good.summary)+
  geom_bar(aes(x=shiftCond,y=m.r),stat='identity')+
  geom_errorbar(aes(x=shiftCond,ymin=lower.r,ymax=upper.r),width = .2)+
  facet_wrap(~lengthCond)+
  ylab('average raw ratings')

p2
