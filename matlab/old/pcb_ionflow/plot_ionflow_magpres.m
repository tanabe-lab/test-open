close all

%�ePC�̃p�X���`
run define_path.m

ratio = 0.4;%���Ey�������p
r_list = [1 2 3 4 5 6];
plot_list_1 = [2 5 6 8];
plot_list_2 = [2 4 6 9];

load([pathname.mat,'/ionflow_magpres/230524/shot15-24.mat'],'grid2D','mpoints','V_i_all','T_i_all','magpres_t_all','magpres_tp_all','magpres_z_all','magpres_all','diff_magpres_all');
mpoints_1 = mpoints;
V_i_all_1 = V_i_all(:,:,plot_list_1);
T_i_all_1 = T_i_all(:,:,plot_list_1);
magpres_t_all_1 = magpres_t_all(:,:,plot_list_1);
magpres_tp_all_1 = magpres_tp_all(:,:,plot_list_1);
magpres_z_all_1 = magpres_z_all(:,:,plot_list_1);
magpres_all_1 = magpres_all(:,:,plot_list_1);
diff_magpres_all_1 = diff_magpres_all(:,:,plot_list_1);
load([pathname.mat,'/ionflow_magpres/230526/shot2-12.mat'],'mpoints','V_i_all','T_i_all','magpres_t_all','magpres_tp_all','magpres_z_all','magpres_all','diff_magpres_all');
mpoints_2 = mpoints;
V_i_all_2 = V_i_all(:,:,plot_list_2);
T_i_all_2 = T_i_all(:,:,plot_list_2);
magpres_t_all_2 = magpres_t_all(:,:,plot_list_2);
magpres_tp_all_2 = magpres_tp_all(:,:,plot_list_2);
magpres_z_all_2 = magpres_z_all(:,:,plot_list_2);
magpres_all_2 = magpres_all(:,:,plot_list_2);
diff_magpres_all_2 = diff_magpres_all(:,:,plot_list_2);

% V_i_all_1(2,:,:) = V_i_all_2(1,:,:);

mpoints_1.r = [mpoints_1.r(1,1); mpoints_2.r];
V_i_all_2(2,:,:) = V_i_all_1(3,:,:);
V_i_all_2 = [V_i_all_1(1,:,:);V_i_all_2];
V_i_all_1 = V_i_all_2;
T_i_all_2(2,:,:) = T_i_all_1(3,:,:);
T_i_all_2 = [T_i_all_1(1,:,:);T_i_all_2];
T_i_all_1 = T_i_all_2;

% V_i_all_1(2,:,:) = V_i_all_2(1,:,:);
% V_i_all_1 = [V_i_all_1;V_i_all_2(5,:,:)];
% T_i_all_1(2,:,:) = T_i_all_2(1,:,:);
% T_i_all_1 = [T_i_all_1;T_i_all_2(5,:,:)];


% V_i_all_1 = filloutliers(V_i_all_1,3);
V_i_mean_1 = mean(V_i_all_1(:,:,:),3);
V_i_sigma_1 = std(V_i_all_1(:,:,:),0,3);
% V_i_all_2 = filloutliers(V_i_all_2,3);
% V_i_mean_2 = mean(V_i_all_2,3);
% V_i_sigma_2 = std(V_i_all_2,0,3);
T_i_mean_1 = mean(T_i_all_1(:,1,:),3);
T_i_sigma_1 = std(T_i_all_1(:,1,:),0,3);

magpres_t_mean = mean([magpres_t_all_1 magpres_t_all_2],3);
magpres_t_sigma = std([magpres_t_all_1 magpres_t_all_2],0,3);
magpres_tp_mean = mean([magpres_tp_all_1 magpres_tp_all_2],3);
magpres_tp_sigma = std([magpres_tp_all_1 magpres_tp_all_2],0,3);
magpres_z_mean = mean([magpres_z_all_1 magpres_z_all_2],3);
magpres_z_sigma = std([magpres_z_all_1 magpres_z_all_2],0,3);
magpres_mean = mean([magpres_all_1 magpres_all_2],3);
magpres_sigma = std([magpres_all_1 magpres_all_2],0,3);
diff_magpres_mean = mean([diff_magpres_all_1 diff_magpres_all_2],3);
diff_magpres_sigma = std([diff_magpres_all_1 diff_magpres_all_2],0,3);

%---------shot�Ԕ�r------------
% figure('Position',[0 300 600 600])
%�C�I���t���[
% for i_shot_1 = plot_list_1
%     plot(mpoints_1.r(r_list),-V_i_all_1(r_list,2,i_shot_1),'LineWidth',2)%Vr
%     hold on
% end
% legend
% ax = gca;
% ax.FontSize = 16;
% title('Ion Flow')
% hold off
% figure('Position',[800 300 600 600])
% for i_shot_2 = plot_list_2
%     plot(mpoints_2.r(r_list),-V_i_all_2(r_list,2,i_shot_2),'LineWidth',2)%Vr
%     hold on
% end
% legend
% ax = gca;
% ax.FontSize = 16;
% title('Ion Flow')
% hold off
% 
% figure('Position',[0 100 600 600])
% %�C�I�����x
% for i_shot_1 = plot_list_1
%     plot(mpoints_1.r(r_list),T_i_all_1(r_list,1,i_shot_1),'LineWidth',2)%Vr
%     hold on
% end
% % % for i_shot_2 = plot_list_2
% % %     plot(mpoints_2.r(r_list),T_i_all_1(r_list,1,i_shot_2),'LineWidth',2)%Vr
% % %     hold on
% % % end
% legend
% ax = gca;
% ax.FontSize = 16;
% title('Ion Temperature')
% hold off
%--------------------------

figure('Position',[800 100 700 600])
% newcolors = [
%     0 0.4470 0.7410%��
%     0.9290 0.6940 0.1250%��
%     ];

% newcolors = [
%     0 0.4470 0.7410%��
%     0.8500 0.3250 0.0980%��
%     ];

% newcolors = [
%     0.8500 0.3250 0.0980%��
%     0.9290 0.6940 0.1250%��
%     ];

newcolors = [
    0.8500 0.3250 0.0980%��
    % 0.9290 0.6940 0.1250%��
    0 0.4470 0.7410%��
    ];

colororder(newcolors)
%---------���c��------------
yyaxis left

%�C�I���t���[
% xq1 = 9:0.1:19;
% p = pchip(mpoints_1.r(r_list),-V_i_mean_1(r_list,2),xq1);
% plot(xq1,p,'LineWidth',2)
% hold on
errorbar(mpoints_1.r(r_list),V_i_mean_1(r_list,2),V_i_sigma_1(r_list,2),'LineWidth',2)%Vr
xlabel('R [cm]')
ylabel('Ion Velocity [km/s]')
left_y_upper = max(V_i_mean_1(r_list,2) + V_i_sigma_1(r_list,2));
left_y_lower = -min(V_i_mean_1(r_list,2) - V_i_sigma_1(r_list,2));
% yticks(-8:4:16)
h1 = yline(0,'--','LineWidth',3);%y=0
h1.Color = newcolors(1,:);

% %�C�I�����x
% errorbar(mpoints_1.r(r_list),T_i_mean_1(r_list,1),T_i_sigma_1(r_list,1),'LineWidth',2)%�C�I�����x
% ylabel('Ion Temperature [eV]')
% left_y_upper = max(T_i_mean_1(r_list,1) + T_i_sigma_1(r_list,1));
% left_y_lower = min(T_i_mean_1(r_list,1) - T_i_sigma_1(r_list,1));
% yticks(0:40:160)

% left_ylim = round(max([left_y_upper -left_y_lower]))+1;
% ylim([-left_ylim*ratio left_ylim])
% ylim([0 left_ylim])
%--------------------------


%---------�E�c��------------
yyaxis right

% %�S���C��
% unit = 1E2;
% errorbar(grid2D.rq(:,1)*unit,magpres_mean(:,1),magpres_sigma(:,1),'LineWidth',2)%���C��
% ylabel('Magneic Pressure [Pa]')
% right_y_upper = max(magpres_mean(:,1) + magpres_sigma(:,1));
% right_y_lower = min(magpres_mean(:,1) - magpres_sigma(:,1));
% % yticks(0:2E4:6E4)

% %�S���C��(����)
% unit = 1E2;
% grid2D.rq(1,:) = [];
% errorbar(grid2D.rq(:,1)*unit,diff_magpres_mean(:,1),diff_magpres_sigma(:,1),'LineWidth',2)%���C��
% ylabel('Derivative of Magneic Pressure [Pa/m]')
% right_y_upper = max(diff_magpres_mean(:,1) + diff_magpres_sigma(:,1));
% right_y_lower = min(diff_magpres_mean(:,1) - diff_magpres_sigma(:,1));
% % yticks(0:2E4:6E4)
% h2 = yline(0,'--','LineWidth',3);%y=0
% h2.Color = newcolors(2,:);

% %���C��(Bt)
% unit = 1E2;
% errorbar(grid2D.rq(:,1)*unit,magpres_t_mean(:,1),magpres_t_sigma(:,1),'LineWidth',2)%���C��
% ylabel('Magneic Pressure [Pa]')
% right_y_upper = max(magpres_t_mean(:,1) + magpres_t_sigma(:,1));
% right_y_lower = min(magpres_t_mean(:,1) - magpres_t_sigma(:,1));
% yticks(0:2E4:6E4)

%���C��(�v���Y�}Bt)
unit = 1E2;
errorbar(grid2D.rq(:,1)*unit,magpres_tp_mean(:,1),magpres_tp_sigma(:,1),'LineWidth',2)%���C��
ylabel('Magneic Pressure [Pa]')
right_y_upper = max(magpres_tp_mean(:,1) + magpres_tp_sigma(:,1));
right_y_lower = min(magpres_tp_mean(:,1) - magpres_tp_sigma(:,1));
% yticks(0:2E4:6E4)

% %���C��(Bz)
% unit = 1E2;
% errorbar(grid2D.rq(:,1)*unit,magpres_z_mean(:,1),magpres_z_sigma(:,1),'LineWidth',2)%���C��
% ylabel('Magneic Pressure [Pa]')
% right_y_upper = max(magpres_z_mean(:,1) + magpres_z_sigma(:,1));
% right_y_lower = min(magpres_z_mean(:,1) - magpres_z_sigma(:,1));
% yticks(0:50:250)

% %�C�I�����x
% errorbar(mpoints_1.r(r_list),T_i_mean_1(r_list,1),T_i_sigma_1(r_list,1),'LineWidth',2)%�C�I�����x
% ylabel('Ion Temperature [eV]')
% right_y_upper = max(T_i_mean_1(r_list,1) + T_i_sigma_1(r_list,1));
% right_y_lower = min(T_i_mean_1(r_list,1) - T_i_sigma_1(r_list,1));
% yticks(40:40:240)

% right_ylim = round(max([right_y_upper -right_y_lower]))+10;
% ylim([-right_ylim*ratio right_ylim])
% ylim([0 right_ylim])

%--------------------------

xlabel('R [cm]')
xlim([8 22])
ax = gca;
ax.FontSize = 20;