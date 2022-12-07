fir_taps_quant = round((fir_coes/max(fir_coes))*2^11);
fir_unfixed = round((fir_coes/max(fir_coes))*2^11);
fir_taps_quant(fir_taps_quant < 0) = 2^12 + fir_taps_quant(fir_taps_quant < 0);
fid = fopen('taps.txt', 'wt');
fprintf(fid, '%x\n', fir_taps_quant);
fclose(fid);

fid = fopen('taps_unfixed.txt', 'wt');
fprintf(fid, '%x\n', fir_unfixed);
fclose(fid);