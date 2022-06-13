close all;  % Close all figures (except those of imtool.)
clearvars;  % Erase all existing variables. Or clearvars if you want.
format long g;
format compact;
fontSize = 13;
%%
% fn = 'nebdMay22.tif'
% BW =imread(fn); str="May22";

% BW =imread('nbdjun1-19.tif'); str="jun1"
% BW =imread('nbdjun-19.tif'); str="jun"
% BW =imread('nbdjul-19.tif'); str="jul"
% BW =imread('nbd_jul21_smooth.tif'); str="jul-erly"


% % comparison 
% BW=imread('may15_sar.tif'); str='SAR'
% BWr=imread('may15_planet.tif'); str='Planet';BW = BWr; BW(BWr>2) = 0;
 
% BW=imread('aug31_sar.tif'); str='SAR'
% BWr=imread('aug26_planet.tif'); str='Planet';BW = BWr; BW(BWr>2) = 0;
 

% Whole BD
% fn='bd_smooth_mar01.tif' %nbdjul-19.tif' %HaorStorage_GEE_exports/SAR_Haors_2019-07-19.tif'  %noriv_fx_
% BW =imread(fn);    str="bd";

fn = 'HaorStorage_GEE_exports/SAR_Haors_Smooth_2020-09-17.tif'; 
BW =imread(fn); str='operational system testing';
%% Processing
BW =logical(BW);
% BW=imbinarize(BW);
% se1 = strel('disk',5);
% BW1=imerode(BW,se1);
se2 = strel('disk',10);
binaryImage=imopen(BW,se2);
% binaryImage=imerode(binaryImage,se1);
% 

% im_1b = bwareaopen(BW,50); %remove less than 5 connected components
% im_1c = imerode(im_1b,strel('disk',10)); %erode with disk of radius 1
% im_1d = imclose(im_1c,strel('disk',10)); %dilate with disk of radius 1
% binaryImage=im_1d;
figure,subplot(1,2,1)
imshow(BW)
title(['Binary image-' str],'FontSize', fontSize, 'Interpreter', 'None')
subplot(1,2,2)
imshow(binaryImage)
title('Erosion + Dilation','FontSize', fontSize, 'Interpreter', 'None')
%%
% CC = bwconncomp(BWco);
% L = labelmatrix(CC);
% imshow(label2rgb(L,'jet','w','shuffle'));
% %%
% stats = regionprops(CC,'Area','Circularity');
% statsL = regionprops(L,'Area','Circularity');
% circ = [stats.Circularity];
% keeperInd = find(circ < 2 & circ>0.5);
% 
% imshow(label2rgb(L==keeperInd,'jet','w','shuffle'));
% 
% %% 
% BW2 = bwpropfilt(BW,'Circularity',[0.1 1.3]);

%%
% Display the image.
figure
subplot(1, 2, 1);
imshow(binaryImage, []);
title('Erosion + Dilation', 'FontSize', fontSize, 'Interpreter', 'None');
% axis on;
% Fill holes

binaryImage = bwconncomp(binaryImage);
% Display the image.
L = labelmatrix(binaryImage);
subplot(1, 2, 2);
imshow(label2rgb(L,'jet','k','shuffle'));
title(['Connected components-' str], 'FontSize', fontSize, 'Interpreter', 'None');
% axis on;
% Let's measure things to see what we're starting with.
props = regionprops(binaryImage, 'Solidity', 'Area','perimeter', 'Eccentricity','Circularity');
allAreas = [props.Area];
allSolidities = [props.Solidity];
allEccentricity=[props.Eccentricity];
allCircularities = 4 * pi * allAreas ./ [props.Perimeter] .^ 2;
% Display the histograms.
% subplot(2, 2, 3);
% histogram(allAreas);
% grid on;
% title('Histogram of Areas', 'FontSize', fontSize, 'Interpreter', 'None');
% subplot(2, 2, 4);
% histogram(allCircularities);
% grid on;
% title('Histogram of circularities', 'FontSize', fontSize, 'Interpreter', 'None');

%% Take the 24 smoothest blobs.
% Get rid of blobs less solid than 0.85%.
% binaryImage2 = bwpropfilt(binaryImage, 'Solidity', [.85, inf]);
% figure;
% % Display the image.
% subplot(2, 1, 1);
% imshow(binaryImage2, []);
% title('Binary Image2 - high solidity', 'FontSize', fontSize, 'Interpreter', 'None');
% axis on;
%% Get rid of blobs with low circularity.
highCircularityIndexes = find( allAreas>=2e5 & allAreas<2e7 & allEccentricity < 0.925 ... %
                             | allAreas>=2e7 ... %  for merged biggest body
                             | allAreas>2000 & allAreas<2e5 & allCircularities>0.11 & allEccentricity < 0.95 );  %1 pixel area=100sq.m, here >0.2 sq km
% highCircularityIndexes = find( allAreas>=200000 ... & allEccentricity < 0.925 ... % Planet: No use of ecc for Planet
%                              | allAreas>2000 & allAreas<200000 & allCircularities>0.08 );
% highCircularityIndexes = find(allCircularities > 0.00   & allAreas>2000 & allEccentricity < 1);  %1 pixel area=100sq.m, here >0.2 sq km

% labeledImage = bwlabel(binaryImage);
binaryImage3 = ismember(L, highCircularityIndexes);
binaryImage3 = imfill(binaryImage3, 'holes');

CC = bwconncomp(binaryImage3);
LC = labelmatrix(CC);
stats = regionprops(CC,'Area','Circularity');
CC.NumObjects
% subplot(1,3,3),
figure,imshow(label2rgb(LC,'jet','k','shuffle')); %'jet',[181, 181, 181]./255));
title(['Haors- ' str] ,'FontSize', fontSize, 'Interpreter', 'None');

% write to tiff
% %%imwrite( binaryImage3, ['bd_processed_haors/haors_' fn])
% geotiffwrite(['outg' fn '.tif'],binaryImage3,geotiffinfo(fn).SpatialRef)

% areas
x=[stats.Area].*1e-4;  % in sq km
xt=x';

%% load saved 34 points for a-v relation
load('aall.mat');
load('vall.mat');
load('dall.mat');
% load('vallrect.mat');
% load('dallrect.mat');

xsaved = aall;
vsaved = vall;
dsaved = dall;
% [p,S] = polyfit(xsaved,ysaved,1);
mdl = fitlm(xsaved,vsaved,'Intercept',false);
% [y_ext,delta] = polyconf(p,xt,S);
[vol,ci] = predict(mdl,xt);

sumci = sum(ci);
sumvolmean = sum(vol)
sumvolmin = sumci(1)
sumvolmax = sumci(2)
del = sumvolmean- sumvolmin

mdl = fitlm(xsaved,dsaved,'Intercept',false);
% [y_ext,delta] = polyconf(p,xt,S);
[vold,cid] = predict(mdl,xt);

sumcid = sum(cid);
sumvolmeand = sum(vold)
sumvolmind = sumcid(1)
sumvolmaxd = sumcid(2)
deld = sumvolmeand - sumvolmind

voltrapez= 0.00391617946904666 *([stats.Area].*1e-4);
volrect= 0.0118*([stats.Area].*1e-4);  %*0.0056 - 0.03; 
% volc=0.0050*([stats.Area].*1e-4);
% 
% 
sumvoltrapez = sum(voltrapez)
sumvolrect = sum(volrect)
% volmin=0.0037*([stats.Area].*1e-4);  % min 
% volmax=0.0042*([stats.Area].*1e-4);  % max 
% sumvolmin = sum(volmin);
% sumvolmax = sum(volmax);
% del = sumvolmean- sumvolmin


% sumvolcmean = sum(volc)
% volcmin=0.0044*([stats.Area].*1e-4);  % min 
% volcmax=0.0055*([stats.Area].*1e-4);  % max 
% sumvolcmin = sum(volcmin);
% sumvolcmax = sum(volcmax);
% delc = sumvolcmean- sumvolcmin

%%
figure
numEd = 20;
 [N,edges] = histcounts(log10(x),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
 histogram(x,10.^edges,'Normalization','probability','FaceColor','#A4A4A4');
%     hold on
%     plot(mean_haorarea,ones(13,1)*0.003,'ro','MarkerFaceColor','y','MarkerSize',8,'LineWidth',1.5)
 ylim([0,0.3]);
 legend('PDF of all haor areas','selected haor areas')
%  title('(b) SAR-based'); %[str ' Probability distribution for Haor Area'],'FontSize', fontSize, 'Interpreter', 'None');
 xlabel('Area, km^2')
 ylabel('Probability')
 set(gca, 'xscale','log')
  a = get(gca,'XTickLabel');
set(gca,'XTickLabel',a,'fontsize',15)


 [N,edges] = histcounts(log10(vol),15); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
 figure, histogram(vol,10.^edges,'Normalization','probability','FaceColor','#A4A4A4','LineStyle','--'	)
 ylim([0,0.4]);
%  title(['Probability distribution for Volume Change'],'FontSize', fontSize, 'Interpreter', 'None');
 xlabel('Volume Storage, km^3')
 ylabel('Probability')
 set(gca, 'xscale','log')
   a = get(gca,'XTickLabel');
set(gca,'XTickLabel',a,'fontsize',15)

% Revised histograms - comment from Tamlin
x=[stats.Area].*1e-4;  % in sq km
xt=x';

% vol= 0.0039*([stats.Area].*1e-4);  %*0.0056 - 0.03; 
% volc=0.0050*([stats.Area].*1e-4);

numEd = 16;
figure
[N,edgesA] = histcounts(log10(x),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
ha = histogram(x,10.^edgesA,'Normalization','probability','FaceColor','#A4A4A4');

Axp = ha.Values;
Ayp = ha.BinEdges(2:numEd+1);


[N,edgesV] = histcounts(log10(vol),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
hv = histogram(vol,10.^edgesV,'Normalization','probability','FaceColor','#A4A4A4','LineStyle','--'	);
Vxp = hv.Values;
Vyp = hv.BinEdges(1:numEd);



% CDF
x=[stats.Area].*1e-4;  % in sq km
xt=x';

% vol= 0.0039*([stats.Area].*1e-4);  %*0.0056 - 0.03; 
% volc=0.0050*([stats.Area].*1e-4);

numEd = 16;
figure
[N,edgesA] = histcounts(log10(x),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
ha = histogram(x,10.^edgesA,'Normalization','cdf','FaceColor','#A4A4A4');

Ax = ha.Values;
Ay = ha.BinEdges(1:numEd);


[N,edgesV] = histcounts(log10(vol),numEd); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
hv = histogram(vol,10.^edgesV,'Normalization','cdf','FaceColor','#A4A4A4','LineStyle','--'	);
Vx = hv.Values;
Vy = hv.BinEdges(1:numEd);

%plots pdf and cdf
figure
subplot(1,2,1)
yyaxis left
plot(Axp, Ayp,'LineWidth',2,'Marker','o')
set(gca, 'yscale','log')
yyaxis right
plot(Vxp, Vyp,'LineWidth',2,'Marker','^')

% title('Probability Distribution')
xlabel('Probability','FontSize',16)
xlim([0,0.41]);
yyaxis left
ylabel('Area, km^2','FontSize',16)
ylim([1e-1,1e4]);
yyaxis right
ylabel('Volume Storage, km^3')
ylim([1e-4,1e2]);

set(gca, 'yscale','log')
a = get(gca,'XTickLabel');
set(gca,'XTickLabel',a,'fontsize',16)

%cdf
subplot(1,2,2)
yyaxis left
plot(Ax, Ay,'LineWidth',2,'Marker','o')
set(gca, 'yscale','log')
yyaxis right
plot(Vx, Vy,'LineWidth',2,'Marker','^')

% title('Cumulative Distribution Function')
xlabel('Cumulative Probability','FontSize',16)
yyaxis left
ylabel('Area, km^2','FontSize',16)
ylim([1e-1,1e4]);
yyaxis right
ylabel('Volume Storage, km^3')
ylim([1e-4,1e2]);


set(gca, 'yscale','log')
a = get(gca,'XTickLabel');  
set(gca,'XTickLabel',a,'fontsize',16)
set(gca,'XTickLabelMode','auto')
 %% Read BWDB data
%  bwdb = xlsread('Haor_AreaDistribution.xlsx',2);
%  x2=[bwdb(:,1)].*1e-2;  % in sq km
% 
% % figure, histogram((x),100);
% 
%  [N2,edges] = histcounts(log10(x2),15); %[ log10(0.2) log10(0.3) log10(0.5) log10(0.8) log10(1) log10(2) log10(5) log10(10) log10(15) log10(20) log10(30) log10(40) log10(60) log10(80) log10(100) log10(150)]);
%  figure, histogram(x2,10.^edges,'Normalization','probability','FaceColor','#A4A4A4','LineStyle','-'	)
%  ylim([0,0.25]);
%  title('(a) Master Plan') %'Probability distribution for Haor Area - BWDB','FontSize', fontSize, 'Interpreter', 'None');
%  xlabel('Area, km^2')
%  ylabel('Frequency')
%  set(gca, 'xscale','log')
%    a = get(gca,'XTickLabel');
% set(gca,'XTickLabel',a,'fontsize',15)
%%
% numberToExtract=-200;
% biggestBlob = ExtractNLargestBlobs(binaryImage3, numberToExtract,2);
% figure,imshow(label2rgb(biggestBlob,'jet','k','shuffle'));
% % Make the number positive again.  We don't need it negative for smallest extraction anymore.
% if numberToExtract == 1
%   caption = sprintf('Extracted Blob');
% elseif numberToExtract > 1
%   caption = sprintf('Extracted %d largest Blobs', numberToExtract);
% elseif numberToExtract < 0
%   caption = sprintf('Extracted %d smallest Blobs', numberToExtract);
% else % It's zero
%   caption = sprintf('Extracted 0 Blobs.');
% end
% title(caption, 'FontSize', fontSize);