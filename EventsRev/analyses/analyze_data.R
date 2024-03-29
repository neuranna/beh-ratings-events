# Created on 2020-05-26 by Anna Ivanova
# Based on the code by Rachel Ryskin
# edited on 2022-02-22 by Anna Ivanova (refactoring, automated worker checks)

rm(list=ls())
library(tidyverse)
library(stringr)
library(stringi)

# READ DATA
filenames=c('../results_raw/Batch_4055141_batch_results.csv',
  '../results_raw/Batch_4055390_batch_results.csv',
  '../results_raw/Batch_4055655_batch_results.csv',
  '../results_raw/Batch_4057413_batch_results.csv')

data <- lapply(filenames, read.csv)
data = do.call("rbind", data)
            
num.trials = 42  # maximum number of trials per participant

# only keep WorkerId and cols that Start with Answer or Input
data = data %>% select(starts_with('Input'),starts_with('Answer'),
                       starts_with('WorkerId'),starts_with('WorkTimeInSeconds'),
                       starts_with('HITId'), starts_with('AssignmentStatus'),
                       starts_with('AssignmentId'))

# gather (specify the list of columns you need)
data = data %>% gather(key='variable',value="value",
                       -WorkerId,-Input.list,-Answer.country,
                       -Answer.English,-Answer.answer, 
                       -WorkTimeInSeconds, -HITId, 
                       -AssignmentStatus, -AssignmentId)

# reformat
data = data %>% 
  separate(variable, into=c('Type','TrialNum'),sep='__',convert=TRUE) %>% 
  spread(key = Type, value = value)

# # exclude bad workers (note: currently done manually)
# data = data %>%
#   filter(!(WorkerId %in% c('AT8S19U5993HR', 'A2R1A479K07ME5')))                   # bad responses

## Summarize ratings data 
data$Answer.Rating <- as.numeric(data$Answer.Rating)

data = data %>% 
  separate(Input.code,into=c('TrialType','Plausibility','Item','xx1','xx2'),sep='_') %>%
  select(-TrialType, -xx1, -xx2)

# clean data
## Look at data by participant 
data.worker = data %>% 
  group_by(WorkerId, HITId) %>%
  summarize(num_questions = length(Answer.Rating),
            num_missed = sum(is.na(Answer.Rating)),
            ratio_missed = num_missed/num_questions,
            native_english = all(Answer.English=='yes'),
            country_usa = all(Answer.country=='USA'),
            filler1 = Answer.Rating[Item=="41"],
            filler2 = Answer.Rating[Item=="42"],
            fillers_correct = (filler1==1 & filler2==7))


# exclude
data.worker.clean = data.worker %>%
  filter(native_english, country_usa,
         ratio_missed<0.2, fillers_correct)



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
  summarize(mean = mean(WorkTimeInSeconds)/60,
            median = median(WorkTimeInSeconds)/60,
            SD = sd(WorkTimeInSeconds/60))

# save worker data
write.csv(data.worker, "data_worker_all.csv")
write.csv(data.worker.clean, "data_worker_clean.csv", row.names=FALSE)


# filter big data df based on worker info and save
data$Item = as.numeric(data$Item)
data.clean = data %>% 
  filter(WorkerId %in% data.worker.clean$WorkerId) %>%
  filter(Item<41) %>%    #fillers
  select(WorkerId, HITId, TrialNum, Answer.Rating, Plausibility, Item, Input.trial) %>%
  arrange(WorkerId, HITId, Item)

write_csv(data.clean,"longform_data.csv")

# sentence stats
dat.sentence = data.clean %>%
  group_by(Input.trial) %>%
  summarize(numRatings = length(Answer.Rating)) %>%
  ungroup() %>%
  filter(numRatings>1) %>%    # one item had a typo, we're excluding it later
  summarize(mean=mean(numRatings),
            min=min(numRatings),
            max=max(numRatings))




# ANALYSES

## Look at data by participant (TODO: add avg rating for plaus and implaus)
data = data %>% 
  group_by(WorkerId) %>%
  mutate(
    na.pct = mean(is.na(Answer.Rating)),
    n = length(Answer.Rating)) %>%
  ungroup()

data.summ = data %>% 
  group_by(WorkerId, Plausibility) %>%
  summarize(
    na.pct = mean(is.na(Answer.Rating)),
    n = length(Answer.Rating),
    mean.rating = mean(Answer.Rating, na.rm = TRUE))

## save a summary of individual subjects' performance
#write_csv(data.summ,"data_summ_by_worker.csv")

z_score = function(xs) {
  (xs - mean(xs)) / sd(xs)
}

#filter for US, English, na, and duplicate, then get scores
data$Item = as.numeric(data$Item)
data.good = data %>%
  filter(Answer.English == "yes" &
         Answer.country == "USA" &
         n <= num.trials) %>%
  filter(!is.na(Answer.Rating)) %>%
  filter(Item<=40)      # remove attention check items

data.good.summary = data.good %>%
  group_by(Plausibility, Item) %>%
  summarize(
    m = mean(Answer.Rating),
    stdev= sd(Answer.Rating),
#    se = stdev/sqrt(n()),
#    upper= m+se*1.96,
#    lower=m-se*1.96
  )
  
## save a summary of individual subjects' performance
data.good.summary = data.good.summary[,c(2,1,3,4)]
#write_csv(data.good.summary[order(data.good.summary$Item),],
#          "EventsRev_data_summ.csv")

# graphs of ratings by condition 
p1 = ggplot(data=data.good.summary)+
  stat_summary(mapping = aes(x = Plausibility, y = m), 
               geom = 'col', fun.y = 'mean', color = 'black')+
  geom_point(mapping = aes(x = Plausibility, y = m), 
             shape=21, size=2, alpha=0.5, stroke=1.5,
             position=position_jitter(width=0.15, height=0),
             show.legend = FALSE)+
  stat_summary(mapping = aes(x = Plausibility, y = m), 
               geom = 'errorbar', fun.data = 'mean_se', 
               color = 'black', size = 1.5, width=0.3)+
  ylab('Plausibility')+
  theme_classic()

ggsave('EventsRev plaus plot.png', p1, width=10, height=10, units="cm")

print(p1)

# SEE RESPONSE CONSISTENCY
data.avg = data.good.summary %>%
  group_by(Plausibility) %>%
  summarize(mean.rating.all = mean(m))
data.merged = merge(data.summ, data.avg) %>%
  mutate(diff = mean.rating - mean.rating.all)

p2 = ggplot(data=data.merged,
            mapping = aes(x=Plausibility, y=mean.rating))+
  geom_point()+
  geom_hline(yintercept=0)+
  theme_classic()
print(p2)

## BOOTSTRAP
# old - no replacement
get_sample_estimate_norepl <- function(data,n) {
  nsub = length(unique(data$WorkerId))
  subIDs = unique(data$WorkerId)
  # bootstrap
  sub_indices = sample(nsub, n)
  subIDs.boot = subIDs[sub_indices]
  data.boot = data %>% filter(WorkerId %in% subIDs.boot) %>%
    group_by(Plausibility) %>%
    summarize(mean.rating.all = mean(Answer.Rating))
  return(data.boot$mean.rating.all[1])
}

bootstrap_mean <- function(data,sub_index) {
  subIDs = unique(data$WorkerId)
  subID.boot = subIDs[sub_index]
  data.boot = data %>% filter(WorkerId ==subID.boot) %>%
    group_by(Plausibility) %>%
    summarize(mean.rating.all = mean(Answer.Rating))
  return(data.boot$mean.rating.all[2])
}

get_sample_estimate <- function(data,n) {
  nsub = length(unique(data$WorkerId))
  # bootstrap
  sub_indices = sample(nsub, n, replace=T)
  data.boot = sapply(sub_indices, 
                     function(x) bootstrap_mean(data,x))
  return(mean(data.boot))
}

data4boot = data.good %>% filter(Input.list %in% c(2,4))
nsub = length(unique(data4boot$WorkerId))
r = sapply(rep(1:nsub, each=100), function(x) get_sample_estimate(data4boot, x))
df = data.frame(num.samples = rep(1:nsub, each=100), mean.plaus = r)

p3 = ggplot(data=df, mapping=aes(x=num.samples, y=mean.plaus))+
  geom_point()+theme_classic()
print(p3)
ggsave('boostrap_plaus_l2.png')

df.var = df %>% group_by(num.samples) %>% summarize(mean.var = var(mean.plaus))
p4 = ggplot(data=df.var,mapping=aes(x=num.samples,y=mean.var))+geom_point()+theme_classic()
ggsave('boostrap_plaus_var_l2.png')
