clc;
clear all;
close all;

x = 512;
y = 512;

fpga_result = 131176;

gold_result = (atan(y/x)/(2*pi)) * 2^20;

error = (fpga_result - gold_result)/gold_result;
fprintf("fpga_result %f, gold_result %f, error %f\n", fpga_result, gold_result, error)