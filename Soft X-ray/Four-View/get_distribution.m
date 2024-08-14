function EE = get_distribution(M,K,gm2d,U,s,v,VectorImage,plot_flag,NL)

Z=U'*VectorImage.';

gmin=-15;gmax=15;
% gmin=-30;gmax=0;
lg_gamma=gmin:1:gmax;
l_g = numel(lg_gamma);
gamma=10.^(lg_gamma);

V1 = zeros(1,l_g);
V2 = zeros(1,l_g);
Vgamma = zeros(1,21);

for n=1:l_g
    rho = M*gamma(n)./(s.^2+M*gamma(n));

    V11 = rho.*(Z.');
    V1(n)=M*sum(V11.^2);
    V2(n)=(sum(rho))^2;
    Vgamma(n)=V1(n)/V2(n);
end

if plot_flag
    figure;semilogy(lg_gamma,Vgamma,'*');
    % figure;plot(lg_gamma,Vgamma,'*');
    xlabel('logγ');
    ylabel('GCV');
end

[~,gamma_index]=min(Vgamma);
E = zeros(1,K);

% for i=1:K
%     if M>K
%         v_1 = [v(i,:) zeros(1,M-K)];
%     else
%         v_1 = v(i,:);
%     end
%     E1 = (s./(s.^2+M*10^(lg_gamma(gamma_index)))).*v_1.*(Z.');
%     E(i)=sum(E1);
% end
% EE = reshape(E,sqrt(K),sqrt(K)); %ここで縦がr、横がzで左下が最小になる

if NL %最大エントロピー
    gamma = 10^(lg_gamma(gamma_index));%GCVも考え直さないと→計算時間やばくなりそう
    L = gm2d; %Lf=g
    Lt = L.';
    g = VectorImage.';
    df = zeros(K, 1);%Newton法の解の修正
    eps = 0.1; % Newton法やめる時ようのε
    iter = 0;
    iterc = 0;
    
    %初期値を決める
    
    for i=1:K
        % v_1 = v(i,:);
        if M>K
            v_1 = [v(i,:) zeros(1,M-K)];
        else
            v_1 = v(i,:);
        end
        E1 = (s./(s.^2+M*10^(lg_gamma(gamma_index)))).*v_1.*(Z.');
        E(i)=sum(E1);
    end
    E(E<1e-5) = 1e-5;
    f = log(E.');


    while df.'*df > eps*(f.'*f) || iter == 0 ||iterc==10
        disp(iter);
        tic
        diagEx = exp(f); %対角成分のままでいることで計算時間が減る
        diaginvEx = diagEx.^(-1);%逆行列計算を楽にする
        diagDx = M*gamma/2*diagEx;
        diaginvDx = diagDx.^(-1);%逆行列計算を楽にする

        Phif = M*gamma/2*(f+1)+ Lt*(L*exp(f)-g);
        A = eye(M) + L*(Lt.*diaginvDx); %A = eye(M)+L*invDx*Lt; %正定値対称行列になっているはずなんだよね
        b = L*(Phif.*diaginvDx); %b = L*invDx*Phif;
        xi = cholesky(A,b);
        %diagproduct = diaginvEx.*diaginvDx;

        %L2正則化する場合
        
        lambda = 10;%良くわかんないけど適当に決めた
        L2 = lambda/2*(f.'*f);
        b2 = L2*(L.'.*diaginvDx).'; % b2 = L*invDx*L2;
        xi2 = cholesky(A,b2); % 時間かかるね
        diaginvs = ((L2-L.'*xi2).*diaginvDx+diagEx).^(-1);
        diagproduct = diaginvs.*diaginvDx;
        

        df = -(Phif-Lt*xi).*diagproduct; %df = -inv?*invDx*(Phif-L.'*xi); 

        % dfが大きく/小さくなりすぎるのを阻止。エラーの原因になる。
        m = 0.5;
        df(df > m) = 1+m - m ./ df(df > m); 
        df(df < -m) = -(1+m) - m ./df(df<-m); 
        
        f = f+ df; %Newton法

        iter = iter+1;
        disp((df.'*df)/(f.'*f));
        if (df.'*df)/(f.'*f)>0.8 % 収束しないで振動しそうになった時は初期値を変えよう
            iterc = iterc+1;
            if iterc >2 && iterc  <10
                f = -1*ones(K,1);
                df = zeros(K,1);
                disp('収束しそうにないから初期値変えた');
                iterc = 10;
            elseif iterc >12
                error('収束しなさそうだよ');
            end
        end
        toc
    end
    E = exp(f);

    EE = reshape(E.',sqrt(K),sqrt(K));

%{
if NL % 最小フィッシャー
    tic
    gamma = 10^(lg_gamma(gamma_index));
    C = Laplacian(sqrt(K)-1);
    H = gm2d;
    G = VectorImage;
    W = eye(size(C, 1));
    diag_idx = find(W);
    for i=1:K
        % v_1 = v(i,:);
        if M>K
            v_1 = [v(i,:) zeros(1,M-K)];
        else
            v_1 = v(i,:);
        end
        E1 = (s./(s.^2+M*10^(lg_gamma(gamma_index)))).*v_1.*(Z.');
        E(i)=sum(E1);
    end
    EE = E;
    EE(EE<1e-5) = -1;
    % ここで10^-5未満を0に設定？
    W(diag_idx) = 1./EE;
    % W(W==Inf) = -1;
    W(W<0) = max(W, [], 'all');
    % if plot_flag
    %     figure;histogram(W(diag_idx));
    % end
    EE = (H' * H + (M * gamma) .* (C'* W * C))^(-1) * H' * G'; 

    EE = reshape(EE, sqrt(K), sqrt(K));
    toc
%}
else
    for i=1:K
        if M>K
            v_1 = [v(i,:) zeros(1,M-K)];
        else
            v_1 = v(i,:);
        end
        E1 = (s./(s.^2+M*10^(lg_gamma(gamma_index)))).*v_1.*(Z.');
        E(i)=sum(E1);
    end
    EE = reshape(E,sqrt(K),sqrt(K)); %ここで縦がr、横がzで左下が最小になる
end

% contourfで単調増加する軸から生成されたmeshgridを使ってプロットすると上下が反転する
EE = flipud(EE);
% figure;imagesc(EE);

end

function C = Laplacian(N_grid)
k=N_grid+1;
K=k*k;
C=zeros(K);
for i=1:1:k
    for j=1:1:k
           C((i-1)*k+j,(i-1)*k+j)=-4;
        if j+1<=k
            C((i-1)*k+j,(i-1)*k+j+1)=1;
        end
        
        if j-1>=1
            C((i-1)*k+j,(i-1)*k+j-1)=1;
        end
        
        if i-1-1>=0
            C((i-1)*k+j,(i-1-1)*k+j)=1;
        end
        
        if i-1+1<=k-1
            C((i-1)*k+j,(i-1+1)*k+j)=1;
        end
    end
end
end
