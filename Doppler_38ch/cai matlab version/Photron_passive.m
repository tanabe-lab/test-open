clear all
close all

show_fig = true;
show_gaussfit = false;
read_from_log = false;
image_intensifier_off_periodic = true;
a039_shotlist_target=2749; % only for read_from_log

data_dir    = '../test data/';
calib_dir   = '../calibration_summary/2022_Funato_38CH/test2/';

p           = readmatrix([calib_dir,'radius.txt']) * 1e-3;
relative    = readmatrix([calib_dir,'relative.txt']);
smile       = readmatrix([calib_dir,'smile.txt']);
center      = readmatrix([calib_dir,'center.txt']);
Instrument  = readmatrix([calib_dir,'instrument.txt']);

width       = 5; % number of pixels for each fiber
frame_rate  = 400e3; % Hz
nframe      = 249; % number of frames taken
offset      = 0;
resolution  = 0.01393172; % d_lambda/dx
tstart      = 450; % us
tend        = 550; % us
edge        = 0.35; % measurement r edge (m)
num         = 50; % number of partion in r for Abel inversion
gauss_fit   = 0; % 1:gauss1, 2:gauss2, 0:custom, -1:deconv

Instrument  = Instrument * resolution;
yy          = (1:num)*(edge-min(p))/num+min(p);yy=yy';
dy          = (edge-min(p))/num;
time        = (1:nframe)/frame_rate * 1e6;

[file,path] = uigetfile('*.tif','Select a file',data_dir);
file_path = fullfile(path,file);
answer = questdlg('Please choose gas','38ch doppler',...
    "H beta","Ar II","H beta");
switch answer
    case "H beta"
        gas_line = 'H beta';
    case "Ar II"
        gas_line = 'Ar II';
end
disp(['Line is chosen as ',gas_line]);

tic;
tstart_i = round(tstart*frame_rate/1e6);
tend_i = round(tend*frame_rate/1e6);

if ~exist(file_path,'file')
    error("File not found.");
end
if gas_line == "H beta"
    M       = 1; 
    lambda0 = 486.133; 
    ti_max  = 60;
elseif gas_line == "Ar II"
    M       = 39.948; 
    lambda0 = 480.6; 
    ti_max  = 300;
else
    error("Wrong gas, or gas not specified.");
end

first_frame_image = flip(rot90(imread(file_path,1),1),1);
Ti_instru = 1.69e8 * M * (2*Instrument*sqrt(2*log(2))/lambda0).^2;
lambda = -((0:(size(first_frame_image,2)-1))-size(first_frame_image,2)/2)*resolution+lambda0;
spectra = zeros(36,size(first_frame_image,2),nframe);
Data = zeros(size(first_frame_image,1),size(first_frame_image,2),nframe);
V_pixel = size(Data,2);
smile_final = smile - 512 + V_pixel/2 + offset;
center_final = center-(1024-length(first_frame_image(:,1)))/2;
bg=find(time < 400,1,'last');

% get image data
disp('Getting spectra data...');
for i = 1:nframe
    Data(:,:,i) = flip(rot90(imread(file_path,i),1),1);
    for j = 1:36
        subimage = Data(center_final(j)-width:center_final(j)+width,:,i);
        spectra(j,:,i)=sum(subimage,1)*relative(j);
        spectra(j,:,i) = spectra(j,:,i) - sum(spectra(j,:,1:bg),3)/bg; % subtract background noise
    end
end

% initialize line-integrated values
Ti_line_integrated = zeros(36,nframe);
Ti_line_integrated_max = zeros(36,nframe);
Ti_line_integrated_min = zeros(36,nframe);
lambda2 = zeros(length(lambda),36);

% smile correction
for i = 1:36
    lambda2(:,i) = -((0:length(lambda)-1)-length(lambda)./2-smile_final(i))*resolution+lambda0;
end

% plot raw spectra of each fiber
if show_fig
    h_spectra = figure(1);
    h_spectra.Position = [0 0 1500 1000];
    sgtitle('Raw spectra of each fiber');
    for i=1:36
        subplot(4,9,i)
        [t_mesh,lamdba_mesh] = meshgrid(time,lambda2(:,i));
        contourf(lamdba_mesh,t_mesh,reshape(spectra(i,:,:),[],size(spectra,3)),64,'LineStyle','none');
        ax = gca;
        ax.XLim = [lambda0-0.5 lambda0+0.5];
        ax.YLim = [400 600];
        ax.CLim = [0 10000];
        xlabel('lambda(nm)');
        ylabel('time(us)');
        title(ax,['spectrum\_CH: ',num2str(i)]);
        colormap("jet");
    end
end

% get line integrated emission by summing raw spectra over lambda
emission_line_integrated = squeeze(sum(sum(spectra,2),1));

% gauss fit line integrated signal
for i = tstart_i:tend_i
    for j = 1:36
        switch gauss_fit
% ******** Gauss fit with default matlab gauss1 function ********
            case 1
                try
                    spectra(j,:,i) = spectra(j,:,i) - min(movmean(spectra(j,:,i),10));
                    f = fit(lambda2(:,j),spectra(j,:,i)','gauss1');
                    coeffvals= coeffvalues(f);
                    ci = confint(f,0.68);
                catch
                    warning('Problem occured during gaussfit. All values are set to 0.');
                    coeffvals = zeros(1,3);
                    ci = zeros(2,3);
                end
                sigma_Ti = coeffvals(3)/sqrt(2);
                sigma_Ti_min = ci(1,3)/sqrt(2);
                sigma_Ti_max = ci(2,3)/sqrt(2);
% ******** Gauss fit with default matlab gauss2 function ********
            case 2
                try
                    options = fitoptions('gauss2', ...
                        'Upper', [Inf Inf 0.2 Inf 0 1e09],...
                        'Lower', [0 -inf 0.06 -Inf 0 1e09]);
                    f = fit(lambda2(:,j),spectra(j,:,i)','gauss2',options);
                    coeffvals= coeffvalues(f);
                    ci = confint(f,0.68);
                catch
                    warning('Problem occured during gaussfit. All values are set to 0.');
                    coeffvals = zeros(1,3);
                    ci = zeros(2,3);
                end
                sigma_Ti = coeffvals(3)/sqrt(2);
                sigma_Ti_min = ci(1,3)/sqrt(2);
                sigma_Ti_max = ci(2,3)/sqrt(2);
% ******** Gauss fit with customized function ********
            case 0
                try
                    [start_A,start_lambda_i] = max(spectra(j,:,i));
                    gaussEqn = 'a0*exp(-1/2*((x-a1)/a2)^2)+a3';
                    options = fitoptions(...
                        'Method', 'NonLinearLeastSquares',...
                        'Algorithm', 'Levenberg-Marquardt',...
                        'StartPoint',[start_A lambda2(start_lambda_i,j) 0.06 0],...
                        'MaxIter',1000);
                    f = fit(lambda2(:,j),spectra(j,:,i)',gaussEqn,options);
                    coeffvals= coeffvalues(f);
                    ci = confint(f,0.68);
                catch
                    warning('Problem occured during gaussfit. All values are set to 0.');
                    coeffvals = zeros(1,4);
                    ci = zeros(2,4);
                end
                sigma_Ti = coeffvals(3);
                sigma_Ti_min = ci(1,3);
                sigma_Ti_max = ci(2,3);
% ******** Gauss fit with customized function + deconvolution of Ti_instrument ********
            case -1
                try
                    [start_A,start_lambda_i] = max(spectra(j,:,i));
                    gaussEqn = 'a0*exp(-1/2*((x-a1)/a2)^2)+a3';
                    options = fitoptions(...
                        'Method', 'NonLinearLeastSquares',...
                        'Algorithm', 'Levenberg-Marquardt',...
                        'StartPoint',[start_A lambda2(start_lambda_i,j) 0.06 0],...
                        'MaxIter',1000);
                    f = fit(lambda2(:,j),spectra(j,:,i)',gaussEqn,options);
                    coeffvals= coeffvalues(f);
                    spectra_gauss = smooth(spectra(j,:,i));
                    % figure(1),clf(1);hold on;plot(lambda2(:,j),spectra_gauss,'r');plot(lambda2(:,j),spectra(j,:,i),'k');hold off;
                    [coeffvals_deconv,ci_deconv,spectra_deconv] = deconvolution(lambda2(:,j),spectra_gauss',Instrument(j));
                    spectra(j,:,i) = spectra_deconv;
                    % fprintf('sigma = %5.4f,sigma_instru = %5.4f,sigma_deconv = %5.4f\n',coeffvals(3),Instrument(j),coeffvals_deconv(3));
                    % fprintf('sigma^2 - sigma_instru^2 = %5.4f,sigma_deconv^2 = %5.4f\n\n',coeffvals(3)^2-Instrument(j)^2,coeffvals_deconv(3)^2)
                catch
                    warning('Problem occured during gaussfit. All values are set to 0.');
                    coeffvals_deconv = zeros(1,3);
                    ci_deconv = zeros(2,3);
                end
                sigma_Ti = coeffvals_deconv(3);
                sigma_Ti_min = ci_deconv(1,3);
                sigma_Ti_max = ci_deconv(2,3);
            otherwise
                sigma_Ti = NaN;
                sigma_Ti_min = NaN;
                sigma_Ti_max = NaN;
                warning('Wrong input. Only -1,0,1,2 are accepted as input.')
        end

% ******** Calculate line integrated Ti ********
        if gauss_fit == -1
            Ti_line_integrated(j,i)=1.69e8 * M * (2 * sigma_Ti * sqrt(2 * log(2)) / lambda0)^2;
            Ti_line_integrated_max(j,i)=1.69e8 * M * (2 * sigma_Ti_max * sqrt(2 * log(2)) / lambda0)^2;
            Ti_line_integrated_min(j,i)=1.69e8 * M * (2 * sigma_Ti_min * sqrt(2 * log(2)) / lambda0)^2;
        else
            Ti_line_integrated(j,i)=1.69e8 * M * (2 * sigma_Ti * sqrt(2 * log(2)) / lambda0)^2 - Ti_instru(j);
            Ti_line_integrated_max(j,i)=1.69e8 * M * (2 * sigma_Ti_max * sqrt(2 * log(2)) / lambda0)^2 - Ti_instru(j);
            Ti_line_integrated_min(j,i)=1.69e8 * M * (2 * sigma_Ti_min * sqrt(2 * log(2)) / lambda0)^2 - Ti_instru(j);
        end
            
        if show_gaussfit
            figure(2);clf(2);
            ax = gca;
            ax.XLim = [lambda0-1 lambda0+1];
            ax.YLim = [-1000 15000];
            title(ax,['time=',num2str(time(i)),',fiber ',num2str(j)]);
            hold on
            line(lambda2(:,j),spectra(j,:,i)','Marker',"o",'Color','k');
            line(lambda2(:,j),f(lambda2(:,j)),'LineStyle',"-",'Color','k')
            yline(0);
            hold off
        end
    end
    fprintf('Finished gaussfit of line integrated spectra at t = %4.2f us\n',time(i));
end

% data that satisfies certain conditions will be kept
checker = (Ti_line_integrated > abs(Ti_line_integrated_max - Ti_line_integrated_min)) ...
       .* (Ti_line_integrated >= 0) ...
       .* (Ti_line_integrated < ti_max);
Ti_line_integrated      = Ti_line_integrated .* checker;
Ti_line_integrated_max  = Ti_line_integrated_max .* checker;
Ti_line_integrated_min  = Ti_line_integrated_min .* checker;

% use this to select data if image intensifier turns off periodically
% this could happen if frame rate is too high
if image_intensifier_off_periodic
    if mean(emission_line_integrated(tstart_i:2:tend_i)) > mean(emission_line_integrated(tstart_i+1:2:tend_i))
        t_index = tstart_i:2:tend_i;
    else
        t_index = tstart_i+1:2:tend_i;
    end
else
    t_index = tstart_i:tend_i;
end

% *********** plot line-integrated emission and Ti ***********
h(1) = figure(3);
h(1).Position = [0 0 500 300];
h(1).Visible = show_fig;
subplot(2,1,1);
hold on
errorbar(time,mean(Ti_line_integrated,1),mean(Ti_line_integrated-Ti_line_integrated_min,1),mean(Ti_line_integrated_max-Ti_line_integrated,1),'k');
errorbar(time(t_index),mean(Ti_line_integrated(:,t_index),1),mean(Ti_line_integrated(:,t_index)-Ti_line_integrated_min(:,t_index),1),mean(Ti_line_integrated_max(:,t_index)-Ti_line_integrated(:,t_index),1),'r');xlim([tstart tend]);ylim([0 ti_max]);
xlabel("time (us)");ylabel("Ti (eV)")
hold off
subplot(2,1,2)
hold on
scatter(time,emission_line_integrated,'k');plot(time,emission_line_integrated,'k');
scatter(time(t_index),emission_line_integrated(t_index),'r');plot(time(t_index),emission_line_integrated(t_index),'r');xlim([tstart tend]);
xlabel("time (us)");ylabel("Emission (a.u.)")
hold off;

% ignore data taken when image intensifier is off
Ti_line_integrated      = Ti_line_integrated(:,t_index);
Ti_line_integrated_max  = Ti_line_integrated_max(:,t_index);
Ti_line_integrated_min  = Ti_line_integrated_min(:,t_index);

% *********** emission-only abel inversion and plot ************
emission = zeros(num,length(time));
interp2 = trigrid_interpor3([squeeze(sum(spectra,2));zeros(1,249)],[p;edge],time,yy);
for i = tstart_i:tend_i
    DIdy = gradient(squeeze(interp2.z(:,i)),yy);
    for j = 1:num
        emission(j,i) = sum(-1/pi*(DIdy(j+1:end)./sqrt(yy(j+1:end).^2-yy(j).^2)*dy));
    end
end
h_emission = figure(4);
h_emission.Visible = show_fig;
[time_mesh,yy_mesh] = meshgrid(time,yy);
contourf(time_mesh,yy_mesh,emission,100,'LineStyle','none');
xlim([400 600]);
xlabel('time(us)');
ylabel('r(m)');
title('Abel inverted result of emission.');

% get ready for abel inversion and the gauss fit after it
lambda_out = lambda(4:length(lambda)-4);
time2=time(t_index);
spectra_interp = zeros(length(yy),length(lambda_out),numel(time2));
for i = 1:numel(t_index)
    % interpolate spectra to uniform lambda mesh
    result = trigrid_interpor_for_r_lambda2([squeeze(spectra(:,:,t_index(i)))',zeros(1,length(lambda))'],[lambda2,lambda'],[p;edge],lambda_out,yy);
    spectra_interp(:,:,i) = result.zq;
end
local_spectra = zeros(size(spectra_interp));
Ti_local = zeros(size(spectra_interp,1),size(spectra_interp,3));
Ti_local_max = Ti_local;
Ti_local_min = Ti_local;
peak = Ti_local;
emission2 = Ti_local;
D_shift = Ti_local;
Ti_instru2 = sum(Ti_instru)/36;
spectra_interp = smooth3(spectra_interp,"box",[floor(num/9),5,1]);

for i = 1:numel(time2)
% ******** Abel inversion ********
    for j = 1:length(lambda_out)
        DIdy = gradient(squeeze(spectra_interp(:,j,i)),yy);
        for k = 2:num-1
            for l = k+1:num
                local_spectra(k,j,i) = local_spectra(k,j,i) - 1/pi*DIdy(l)*dy/(sqrt(yy(l)^2-yy(k)^2));
            end
        end
    end
    emission2(:,i) = sum(local_spectra(:,:,i),2);
    for k = 1:num
        switch gauss_fit
% ******** Gauss fit with default matlab gauss1 function ********
            case 1
                try
                    local_spectra(k,:,i) = local_spectra(k,:,i) - min(movmean(local_spectra(k,:,i),10));
                    f = fit(lambda_out',squeeze(local_spectra(k,:,i))','gauss1');
                    coeffvals= coeffvalues(f);
                    ci = confint(f,0.68);
                catch
                    warning('Problem occured during gaussfit. All values are set to 0.');
                    coeffvals = zeros(1,3);
                    ci = zeros(2,3);
                end
                sigma_Ti = coeffvals(3)/sqrt(2);
                sigma_Ti_min = ci(1,3)/sqrt(2);
                sigma_Ti_max = ci(2,3)/sqrt(2);
% ******** Gauss fit with default matlab gauss2 function ********
            case 2
                 try
                    options = fitoptions('gauss2',...
                        'Upper', [Inf Inf 0.2 Inf 0 1e09],...
                        'Lower', [0 -inf 0.08 -Inf 0 1e09]);
                    f = fit(lambda_out',squeeze(local_spectra(k,:,i))','gauss2',options);
                    coeffvals= coeffvalues(f);
                    ci = confint(f,0.68);
                catch
                    warning('Problem occured during gaussfit. All values are set to 0.');
                    coeffvals = zeros(1,3);
                    ci = zeros(2,3);
                end
                sigma_Ti = coeffvals(3)/sqrt(2);
                sigma_Ti_min = ci(1,3)/sqrt(2);
                sigma_Ti_max = ci(2,3)/sqrt(2);
% ******** Gauss fit with customized function ********
            case {0,-1}
                try
                    [start_A,start_lambda_i] = max(local_spectra(k,:,i));
                    gaussEqn = 'a0*exp(-1/2*((x-a1)/a2)^2)+a3';
                    options = fitoptions(...
                        'Method', 'NonLinearLeastSquares',...
                        'Algorithm', 'Levenberg-Marquardt',...
                        'StartPoint',[start_A lambda_out(start_lambda_i) 0.06 0],...
                        'MaxIter',1000);
                    f = fit(lambda_out',squeeze(local_spectra(k,:,i))',gaussEqn,options);
                    coeffvals= coeffvalues(f);
                    ci = confint(f,0.68);
                catch
                    warning('\nProblem occured during gaussfit. All values are set to 0.');
                    coeffvals = zeros(1,3);
                    ci = zeros(2,3);
                end
                sigma_Ti = coeffvals(3);
                sigma_Ti_min = ci(1,3);
                sigma_Ti_max = ci(2,3);
            otherwise
                warning('\nWrong gaussfit method.');
                coeffvals = NaN;
                sigma_Ti = NaN;
                sigma_Ti_min = NaN;
                sigma_Ti_max = NaN;
        end
% ******** Calculate line integrated Ti and flow ********
        if gauss_fit == -1
            Ti_local(k,i)=1.69e8 * M * (2 * sigma_Ti * sqrt(2 * log(2)) / lambda0)^2;
            Ti_local_max(k,i)=1.69e8 * M * (2 * sigma_Ti_max * sqrt(2 * log(2)) / lambda0)^2;
            Ti_local_min(k,i)=1.69e8 * M * (2 * sigma_Ti_min * sqrt(2 * log(2)) / lambda0)^2;
        else
            Ti_local(k,i)=1.69e8 * M * (2 * sigma_Ti * sqrt(2 * log(2)) / lambda0)^2 - Ti_instru2;
            Ti_local_max(k,i)=1.69e8 * M * (2 * sigma_Ti_max * sqrt(2 * log(2)) / lambda0)^2 - Ti_instru2;
            Ti_local_min(k,i)=1.69e8 * M * (2 * sigma_Ti_min * sqrt(2 * log(2)) / lambda0)^2 - Ti_instru2;
        end
        peak(k,i) = coeffvals(1);
        D_shift(k,i) = coeffvals(2);
        
        if show_gaussfit
            figure(5);clf(5)
            ax = gca;
            ax.XLim = [lambda0-1 lambda0+1];
            ax.YLim = [-1000 15000];
            title(ax,['time=',num2str(time2(i)),',r=',num2str(yy(k))]);
            hold on
            line(lambda_out',squeeze(local_spectra(k,:,i)),'Marker',"o",'Color','k');
            line(lambda_out',f(lambda_out'),'LineStyle',"-",'Color','k')
            yline(0);
            hold off
        end

        fprintf('Finished gaussfit of Abel inverted spectra at t = %4.2f us, r = %4.3f m\n',time2(i),yy(k));
    end
end

% data that satisfies certain conditions will be kept
checker = ...
    (peak > 0) .* ...
    (Ti_local > Ti_local_max - Ti_local_min) .* ...
    (abs(Ti_local_max - Ti_local_min) < 10) .*...
    (Ti_local > 0) .* ...
    (isfinite(Ti_local)) .* ...
    (Ti_local < ti_max);
Ti_local = Ti_local.*checker;
Ti_local_max = Ti_local_max.*checker;
Ti_local_min = Ti_local_min.*checker;
checker = Ti_local > 0;

% ******** Smoothing ********
Ti_local2 = Ti_local;
Ti_local_max2 = Ti_local_max;
Ti_local_min2 = Ti_local_min;
for kkk = 1:100
    for i = 1:numel(time2)
        for j = 2:num-2
            if checker(j,i) == 0
                Ti_local2(j,i) = (Ti_local2(j+1,i) + Ti_local2(j-1,i))/2;
                Ti_local_max2(j,i) = (Ti_local_max2(j+1,i) + Ti_local_max2(j-1,i))/2;
                Ti_local_min2(j,i) = (Ti_local_min2(j+1,i) + Ti_local_min2(j-1,i))/2;
            end
        end
    end
end

% plotting smoothed Ti
[time_mesh,yy_mesh] = meshgrid(time2,yy);
h(2) = figure(6);
h(2).Position = [0 0 600 200];
h(2).Visible = show_fig;
contourf(time_mesh,yy_mesh,smoothdata(Ti_local2),-ti_max:0.1:ti_max,'LineStyle','none');
clim([0 ti_max]);
title('smoothed Ti (eV)');
xlabel('time(us)');
ylabel('r(m)');
colormap('jet');
colorbar;

if ~show_fig
    close all
end

toc

function file_path = get_file_doppler38ch(data_dir,date,shot_num)
    % generate file_path from root data directory, date, and shot number
    % original path of the form shot11_
    file_path = '';
    all_data_files = dir(fullfile(data_dir));
    for i = 1:length(all_data_files)
        if convertCharsToStrings(all_data_files(i).name) == num2str(date)
            todays_files = dir(fullfile([data_dir,num2str(date)]));
            for j = 1:length(todays_files) 
                % get shot_number between the keyword shot and the next _
                index = strfind(todays_files(j).name, 'shot');
                if isempty(index)
                    continue
                end
                index2 = strfind(todays_files(j).name(index:end),'_');
                if convertCharsToStrings(todays_files(j).name(index+4:index+index2(1)-2)) == num2str(shot_num)
                    file_path = [todays_files(j).folder,'/',todays_files(j).name,'/',todays_files(j).name,'.tif'];
                    return
                end
            end
        end
    end
    if isempty(file_path)
        disp(['Failed to get file_path for date=',num2str(date),',shot=',num2str(shot_num)]);
    end
end
