function [bz, ok_bz, ok_bz_plot] = ng_replace(bz, ok_bz, sheet_date)
%bz生信号を前後の信号で線形補完して置き換え
%   日付ごとに置き換えるverを変える
%   ok_bz:【input】生きているch→【output】生きているch＋補間したch
%   ok_bz_plot：【output】もともと生きているchのみ
if sheet_date<230103
    bz=bz;
    ok_bz=ok_bz;
else
    r1=0.021;
    r2=0.0535;
    bz(:,8)=(bz(:,7)+bz(:,9))./2;
    bz(:,16)=(bz(:,15)+bz(:,17))./2;
    bz(:,22)=(bz(:,21)+bz(:,23))./2;
    bz(:,26)=(bz(:,25)+bz(:,27))./2;
    bz(:,28)=(bz(:,27)+bz(:,29))./2;
    bz(:,31)=(r1.*bz(:,21)+r2.*bz(:,41))./(r1+r2);
    bz(:,32)=(r1.*bz(:,22)+r2.*bz(:,42))./(r1+r2);
    bz(:,33)=(r1.*bz(:,23)+r2.*bz(:,43))./(r1+r2);
    bz(:,39)=(bz(:,38)+bz(:,40))./2;
    bz(:,63)=(bz(:,62)+bz(:,64))./2;
    bz(:,95)=(bz(:,94)+bz(:,96))./2;
    ok_bz_plot=ok_bz;
    ok_bz([8 16 22 26 28 31 32 33 39 63 95])=true;
end
end