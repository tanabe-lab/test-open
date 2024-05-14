clear all
addpath '/Users/rsomeya/Documents/lab/matlab/common';
run define_path.m

date = 230830;%230523;
shot = 12;%8;
ch = [1 3 4];% 7 8];
calib(ch) = [116.6647,225.71,174.19];%,63.9568,223.2319];
FIG.start = 390;%0以上0.1の倍数(us)
FIG.end = 450;%FIG.start以上0.1の倍数(us)
FIG.smooth = 20;%移動平均長さ(1以下なら移動平均とらない)

rgw2txt(date,shot)
plot_rogowski(pathname,date,shot,ch,calib,FIG)