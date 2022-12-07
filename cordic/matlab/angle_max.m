clc;
clear all;
close all;

N = 20;
angle = zeros(1, N);
fix_angle = zeros(1, N);
multi_factor =1;
angel_sum = 0;
xn = 1;
fid = fopen('tmp.txt', 'wt');
fid_angle = fopen('fix_angle.txt', 'wt');
tmp = 1;
for i=1:N
    angle(i) = atan(1/(bitshift(1,i-1)));
    fix_angle(i) = round((angle(i)/(2*pi))*2^20);
    xn = xn + (1/(bitshift(1,i-1)));
    multi_factor = cos(angle(i)) * tmp;
    tmp = multi_factor;
    angel_sum = angel_sum + angle(i);
    fprintf(fid, 'tan(theta)is %f, angle(%i) is %f Radian, cos_theta is %f, angle_sum is %f, factor is %f\n',1/(bitshift(1,i-1)), i, angle(i), cos(angle(i)), angel_sum, multi_factor);
    fprintf(fid_angle, '%x\n', fix_angle(i));
end
fprintf(fid,'multi_factor is %f, angel_sum is %f degrees, xn=%f\n',multi_factor, (angel_sum/(2*pi))*360, xn);
fclose(fid);
fclose(fid_angle);