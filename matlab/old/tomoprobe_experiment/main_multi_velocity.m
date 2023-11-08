function [] = main_multi_velocity(inversion_method,draw_spectra,draw_result,draw_type,draw_analisis,draw_compare)
%tΟ·(1~5),XyNg`ζ,Κ`ζ,ό(1)/O³(2),ͺΝ`ζ,δr`ζ

mp = 1.67e-27;%zqΏΚ(kg)
kB = 1.60e-19;%{c}θ(J/eV)
A = 40;%ΏΚ

nz = 1;%vͺ_ZϋόΤ(nz = 1:-2.1cm, nz = 2:+2.1cm)
NT = 6;%vͺgKΤ(1~6)
NR = 7;%vͺ_(1~7)
NData = 5;%f[^(1~5)
Vmean_z_t = zeros(NT,NR);%tΜ½ΟVmean_z
Vmean_r_t = zeros(NT,NR);%tΜ½ΟVmean_r
Sz_t = zeros(NT,NR);%tΜVmean_zΜWΞ·
Sr_t = zeros(NT,NR);%tΜVmean_rΜWΞ·
Vmean_z2 = zeros(NData,NR);
Vmean_r2 = zeros(NData,NR);
Vmean_z2_t = zeros(NT,NR);%tΜ½ΟV^2mean_z
Vmean_r2_t = zeros(NT,NR);%tΜ½ΟV^2mean_r
Sz2_t = zeros(NT,NR);%tΜV^2mean_zΜWΞ·
Sr2_t = zeros(NT,NR);%tΜV^2mean_rΜWΞ·
% Vmean_t = zeros(NT,NR);%tΜ½ΟVmean

% Vmean_z = zeros(NData,NR);
% Vmean_r = zeros(NData,NR);
% Tz = zeros(NData,NR);
% Tr = zeros(NData,NR);

% for t = 1:NT
%     for j = 1:NR
%         for k = 1:NData
%             [Vmean_z(k,j),Vmean_r(k,j),Tz(k,j),Tr(k,j)] = main(463+2*t,nz,j,k,inversion_method,draw_spectra,draw_result,draw_type,draw_analisis,draw_compare);
%         end
%     end
%     %ΫΆ
%     save(['mat/save_fwhm_plus_',num2str(463+2*t),'us.mat'],'Vmean_z','Vmean_r','Tz','Tr')
%     Tz_t(t,:) = mean(Tz);
%     Tr_t(t,:) = mean(Tr);
%     Sz_t(t,:) = std(Tz);
%     Sr_t(t,:) = std(Tr);
% end

for t = 1:NT
    %Ηέή
    load(['mat/save_fwhm_minus_',num2str(463+2*t),'us.mat'],'Vmean_z','Vmean_r')
    for j = 1:NR
        for k = 1:NData
            Vmean_z2(k,j) = Vmean_z(k,j)^2*10^6*A*mp/(2*kB);
            Vmean_r2(k,j) = Vmean_r(k,j)^2*10^6*A*mp/(2*kB);
        end
    end
    Vmean_z_t(t,:) = mean(Vmean_z);
    Vmean_r_t(t,:) = mean(Vmean_r);
    Vmean_z2_t(t,:) = mean(Vmean_z2);
    Vmean_r2_t(t,:) = mean(Vmean_r2);
    Sz_t(t,:) = std(Vmean_z);
    Sr_t(t,:) = std(Vmean_r);
    Sz2_t(t,:) = std(Vmean_z2);
    Sr2_t(t,:) = std(Vmean_r2);
end
%-------------------[·xΜκ³ͺzπvbg-------------------
plot_velocity(NT,NR,Vmean_z2_t,Vmean_r2_t,Sz2_t,Sr2_t)

end
