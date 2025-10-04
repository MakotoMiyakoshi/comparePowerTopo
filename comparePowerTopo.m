% comparePowerTopo - EEG power analysis tool for comparing two EEGLAB datasets. 
% Usage:
%        >>  comparePowerTopo [This launches three dialogue windows to let
%                           users to enter information via Matlab's GUI for
%                           the path for dataset 1, another window to enter
%                           the path for dataset 2, and cutoff frequencies
%                           for band-pass filter. Requires full channel
%                           information or at least valid 10-20 channels
%                           labels such as Fz, Cz, Pz, ... The type of
%                           filter used is FIR Hamming (-53 db/oct),
%                           transition bandwidth == 1 (fixed).] 

% Copyright (C) Makoto Miyakoshi, Cincinnati Children's Hospital Medical Center
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

% History
% 10/03/2025 Makoto. Created at San Francisco Airport in front of gate G2 at 11:44 pm.

function comparePowerTopo

    %% Step 1: Select files
    [files1, path1] = uigetfile('*.set','Select Group 1 .set files','MultiSelect','off');
    [files2, path2] = uigetfile('*.set','Select Group 2 .set files','MultiSelect','off');
    if ischar(files1), files1 = {files1}; end
    if ischar(files2), files2 = {files2}; end
    EEG1 = pop_loadset('filename', files1, 'filepath', path1);
    EEG2 = pop_loadset('filename', files2, 'filepath', path1);

    if EEG1.nbchan ~= EEG2.nbchan
        error('Number of channels do not match.')
    end
    
    %% Step 2: User-specified frequency band
    prompt = {'Enter lower freq (Hz):','Enter upper freq (Hz):'};
    dlgtitle = 'Frequency band';
    definput = {'8','13'};
    answer = inputdlg(prompt, dlgtitle, [1 40], definput);
    fmin = str2double(answer{1});
    fmax = str2double(answer{2});
    
    %% Step 3: Compute band power for each subject
    fprintf('Computing band power %d-%d Hz...\n', fmin, fmax);
    data1 = compute_bandpower_group(EEG1, fmin, fmax);
    data2 = compute_bandpower_group(EEG2, fmin, fmax);
    
    %% Step 4: Statistics (per channel)
    nbChan = EEG1.nbchan;
    tvals = zeros(nbChan,1);
    dvals = zeros(nbChan,1);
    
    for ch = 1:nbChan
        [~,~,~,stats] = ttest2(data1(ch,:), data2(ch,:));
        tvals(ch) = stats.tstat;
        dvals(ch) = cohens_d(data1(ch,:), data2(ch,:));
    end
    
    %% Step 5: Plot scalp maps
    
    % Heuristic solution for a situation where channel labels are present but locations absent.
    if ~isempty(EEG1.chanlocs(1).labels) & isempty(EEG1.chanlocs(1).X)
        warning('Channel location information absent: Attempting to load it...')
        EEG1 = pop_chanedit(EEG1, {'lookup','standard_1005.elc'});
    end

    figure;
    subplot(1,2,1) % t-stats
    topoplot(tvals, EEG1.chanlocs);
    title(sprintf('t-statistics (%d-%d Hz)', fmin, fmax));
    colorbar;

    subplot(1,2,2) % Cohen's d
    topoplot(dvals, EEG1.chanlocs, 'maplimits', [-1 1]);
    title(sprintf('Cohen''s d (%d-%d Hz)', fmin, fmax));
    colorbar;
    
    fprintf('Done.\n');
end

%% Helper: Compute band power for a group of files
function instPower = compute_bandpower_group(EEG, fmin, fmax)

% Bandpass filter. TBW is fixed to 1 Hz.
[forder, dev] = firwsord('hamming', EEG.srate, 1); % TBW = 1 Hz.
EEG_bp = pop_firws(EEG, 'fcutoff', [fmin fmax], 'ftype', 'bandpass', 'wtype', 'hamming', 'forder', forder, 'minphase', 0, 'usefftfilt', 0, 'plotfresp', 0, 'causal', 0);

% Hilbert transform to get analytic signal
analytic = hilbert(double(EEG_bp.data')');

% Envelope (amplitude) squared = power
instPower = abs(analytic).^2;

end

%% Helper: Cohen's d
function d = cohens_d(x1, x2)
    n1 = length(x1);
    n2 = length(x2);
    s1 = var(x1,1);
    s2 = var(x2,1);
    s_pooled = sqrt(((n1-1)*s1 + (n2-1)*s2) / (n1+n2-2));
    d = (mean(x1)-mean(x2)) / s_pooled;
end