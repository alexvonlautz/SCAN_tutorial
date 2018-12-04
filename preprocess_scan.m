% Scan Master example EEG preprocessing with SPM

%%%%%%%% Note %%%%%%%%%%
% We would usually downsample earlier in the pipeline.
% However, because of electrical stimulation we could get problems
% Also, preprocessing usually includes eye-blink removal and
% manual/automatic artefact correction
%%%%%%%%       %%%%%%%%%%
%
% Alexander von Lautz, Neurocomputation Neuroimaging Unit, FU Berlin
%% 
clear all

%% Set up locations

preproc_dir = '/home/avl/Schreibtisch/Scan/';

%% Load data into SPM
D = spm_eeg_load([preproc_dir 'scan01']);

%% Run through preprocessing steps
% ===========================================================
%                    re-reference to average montage
% ===========================================================

S=[];
S.D=D;
S.refchan='average';
D= spm_eeg_reref_eeg(S);

% ===========================================================
%                    high-pass filter
% ===========================================================
S             = [];
S.D           = D;
S.band        = 'high';
S.freq        = 0.1;
S.prefix      = 'erp';
D             = spm_eeg_filter(S);

% ===========================================================
%                    low-pass filter
% ===========================================================
S             = [];
S.D           = D;
S.band        = 'low';
S.freq        = 96;
S.prefix      = 'f';
D             = spm_eeg_filter(S);

% ===========================================================
%                    band stop filter line noise
% ===========================================================

if S.freq>48
    
    S             = [];
    S.D           = D;
    S.band        = 'stop';
    S.freq        =[49 51];
    D             = spm_eeg_filter(S);
end

% ===========================================================
%                    downsampling
% ===========================================================
S             = [];
S.D           = D;
S.fsample_new = 256;
D             = spm_eeg_downsample(S);

% ===========================================================
%  coregister the data using individual electrode positions
% ===========================================================
S              = [];
S.D            = D;
S.task         = 'coregister';
S.save         = 1;
S.useheadshape = 0;
D              = spm_eeg_prep(S);

%% Epoching

% The value we want to epoch to is the 31,32,41,42, not the sending of
% the trigger (128). But we need the exact timing of 128. Luckily, the
% values come after another, so with a bit of code we can change the
% numbers and overwrite the 128 with the condition label 31-42.
% D=spm_eeg_load('/home/avl/Schreibtisch/Scan/dfferpMscan01')
evtlog=[31 32 41 42];
tmp=D.events;
for j=1:length(tmp)
    if isempty(tmp(j).value)
        tmp(j).value=999;
    end
end
evt=[tmp.value];
for i=4:2:length(evt) % I go from 4 on because there are a few extra triggers when the EEG starts up
    tmp(i).value=tmp(i+1).value;
    tmp(i-1).value=128;% We exchange the values for previous trial
end
D      = events(D, 1, tmp); % store recoded trigger in events
% define epochs
S    = [];
S.D  = D;
S.bc = 0; % baseline correction: off

% Timewindow
S.timewin = [-50 500];

for j=1:length(evtlog)
    S.trialdef(j).conditionlabel = num2str(evtlog(j));
    S.trialdef(j).eventtype      = 'STATUS';
    S.trialdef(j).eventvalue     = evtlog(j);
end
S.reviewtrials = 0;
S.save         = 0;
D              = spm_eeg_epochs(S);
save(D);
