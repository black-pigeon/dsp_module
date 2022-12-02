clear all;close all;clc;
%=======================================================
% generating a cos wave data with txt hex format
%=======================================================

fc          = 0.5e6 ;      % 中心频率
fn          = 20e6 ;         % 杂波频率
Fs          = 100e6 ;        % 采样频率
T           = 1/fc ;        % 信号周期
Num         = round(Fs * T) ;     % 周期内信号采样点数
t           = (0:Num-1)/Fs ;      % 离散时间
cosx        = sin(2*pi*fc*t) ;    % 中心频率正弦信号
cosn        = sin(2*pi*fn*t) ;    % 杂波信号
cosy        = mapminmax(cosx + cosn) ;     %幅值扩展到（-1,1） 之间
cosy_quant = zeros(1, Num);
for i=1:Num
    if cosy(i)==1
        cosy_quant(i) =  floor(cosy(i)*2^11)-1;
    elseif cosy(i)==-1
        cosy_quant(i) = 2^12 + floor(cosy(i)*2^11 +1);
    elseif cosy(i)<0
        cosy_quant(i) = 2^12 + floor(cosy(i)*2^11);
    else
        cosy_quant(i) = floor(cosy(i)*2^11);
    end
end
% cosy_quant  = floor(cosy*2^11);
% cosy_quant(cosy_quant < 0) = 2^12 + cosy_quant(cosy_quant < 0);
cosy_dig    = floor((2^11-1) * cosy + 2^11) ;     %幅值扩展到 0~4095
fid         = fopen('signal_source.txt', 'wt') ;  %写数据文件
fprintf(fid, '%x\n', cosy_quant) ;
fclose(fid) ;

%时域波形
figure(1);
subplot(121);plot(t,cosx);hold on ;
plot(t,cosn) ;
subplot(122);plot(t,cosy_quant) ;

figure(2);
plot(t, cosy_dig);

%频域波形
fft_cosy    = fftshift(fft(cosy, Num)) ;
f_axis      = (-Num/2 : Num/2 - 1) * (Fs/Num) ;
figure(5) ;
plot(f_axis, abs(fft_cosy)) ;