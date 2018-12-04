% EEG classification with DMLT example
% 
% Alexander von Lautz,
% Neurocomputation Neuroimaging Unit, FU Berlin
% Oxford Centre for Human Brain Activity, University of Oxford

% Needed for script: 
% - Data in SPM format (or already in fieldtrip format)
% - Epoched data with D.conditions field

% What it does

% - Run an EEG classification using SVM

%% Set up paths to toolboxes, run SPM
% addpath('E:\spm12\') %
% addpath('E:\fieldtrip-20171212/external/dmlt') 
% spm eeg

%% Load SPM data set, transform to fieldtrip

D=spm_eeg_load('/home/avl/Schreibtisch/Scan/edfferpMscan01.mat');
data=fttimelock(D);
conditions=D.conditions;

%% Prepare data
cfg=[]; % Insert more preprocessing steps here, e.g. baseline correction
data=ft_preprocessing(cfg, data);

%% Inspect data
figure;
cfg=[];
cfg.layout  = 'biosemi64.lay'; 
ft_multiplotER(cfg,data)
%% Select conditions

low=find(cellfun(@any,regexp(conditions,'31|41')));
high=find(cellfun(@any,regexp(conditions,'32|42')));

cfg             = [];
cfg.parameter   = 'trial';
cfg.keeptrials  = 'yes'; % classifiers operate on individual trials
cfg.channel     = 'EEG'; % e.g. C1,C3 for contralateral S1 / occipital channels only for visual areas/alpha,
cfg.trials      = low;
dataleft   = ft_timelockanalysis(cfg,data);
cfg.trials      = high;
dataright  = ft_timelockanalysis(cfg,data);

%% Do classification

cfg         = [];
cfg.layout  = 'biosemi64.lay';
cfg.method  = 'crossvalidate';% crossvalidate will use standard SVM
cfg.design  = [ones(size(dataleft.trial,1),1); 2*ones(size(dataright.trial,1),1)]';
cfg.latency = [0 .2]; % specify which timepoints
cfg.channel = 'C1';% specify channel
stat = ft_timelockstatistics(cfg,dataleft,dataright);

%% Do classification with timesteps
time=data.time;
toi=[-0.05 0.5];%time of interest
toi_steps=time(time>=toi(1)&time<=toi(2));%select toi points
for timepoint=1:length(toi_steps)-1
cfg         = [];
cfg.layout  = 'biosemi64.lay';
cfg.channel = 'C1';
cfg.method  = 'crossvalidate';% crossvalidate will use standard SVM
cfg.design  = [ones(size(dataleft.trial,1),1); 2*ones(size(dataright.trial,1),1)]';
cfg.latency = [toi_steps(timepoint) toi_steps(timepoint+1)]; % specify which timepoints
stat = ft_timelockstatistics(cfg,dataleft,dataright);
statistic_timed(timepoint)=stat.statistic.accuracy;
end

%% plot the timecourse
figure;
plot(toi_steps(2:end),statistic_timed)